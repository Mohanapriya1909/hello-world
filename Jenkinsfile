pipeline {
  agent any

  environment {
    AWS_REGION = "us-east-1"
    ECR_REPO = "060795904368.dkr.ecr.us-east-1.amazonaws.com/hello-world" // replace with your repo URI
    IMAGE_TAG = "${env.BUILD_NUMBER}"
    SONAR_HOST_URL = "https://sonarcloud.io"
    SONAR_TOKEN_CREDENTIAL_ID = "sonar-token"
    GIT_CREDENTIALS_ID = "git-creds"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build & Test') {
      tools { maven 'Maven-3.8.6' } // only if you configured tool; otherwise ensure mvn is on PATH
      steps {
        sh 'mvn -B -DskipTests=false clean package'
      }
      post {
        always {
          junit '**/target/surefire-reports/*.xml'
          archiveArtifacts artifacts: 'target/site/jacoco/**', allowEmptyArchive: true
        }
      }
    }

    stage('Sonar Analysis') {
  steps {
    withCredentials([
      string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN'),
      string(credentialsId: 'sonar-org', variable: 'SONAR_ORG')
    ]) {
      sh """
        mvn -B sonar:sonar \
          -Dsonar.login=${SONAR_TOKEN} \
          -Dsonar.host.url=https://sonarcloud.io \
          -Dsonar.organization=${SONAR_ORG} \
          -Dsonar.projectKey=mohanapriya1909_hello-world \
          -Dsonar.projectName="hello-world"
      """
    }
  }
}


    stage('Build Docker image & Push to ECR') {
      environment {
        AWS_ACCOUNT_ID = sh(script: "aws sts get-caller-identity --query Account --output text", returnStdout: true).trim()
      }
      steps {
        script {
          // login to ECR
          sh "aws ecr get-login-password --region ${env.AWS_REGION} | docker login --username AWS --password-stdin ${env.ECR_REPO.split('/')[0]}"
          // build image
          sh "docker build -t ${env.ECR_REPO}:${env.IMAGE_TAG} ."
          // push
          sh "docker push ${env.ECR_REPO}:${env.IMAGE_TAG}"
          // update latest tag
          sh "docker tag ${env.ECR_REPO}:${env.IMAGE_TAG} ${env.ECR_REPO}:latest && docker push ${env.ECR_REPO}:latest"
        }
      }
    }

    stage('Deploy to EKS') {
      steps {
        // we assume kubectl is configured for jenkins user and EKS cluster is accessible
        sh '''
          # Update k8s deployment image if deployment exists, otherwise apply k8s manifest
          if kubectl get deployment hello-world-deployment >/dev/null 2>&1; then
            kubectl set image deployment/hello-world-deployment hello-world-container=${ECR_REPO}:${IMAGE_TAG} --record
          else
            kubectl apply -f k8s/deployment.yaml
          fi
        '''
      }
    }
  }

  post {
    success { echo "Pipeline completed successfully" }
    failure { echo "Pipeline failed" }
  }
}
