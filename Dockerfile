# Dockerfile (place at repo root)
FROM eclipse-temurin:17-jdk-jammy AS build
# optional: build inside Docker (we already build with Jenkins), so only runtime stage used below

# runtime image
FROM eclipse-temurin:17-jdk-jammy
WORKDIR /app

# copy the application jar produced by Maven in the Jenkins workspace
# adjust the wildcard if your artifact name differs
COPY target/*-SNAPSHOT.jar app.jar

# expose port used by your app (change if different)
EXPOSE 8080

# run the jar
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
