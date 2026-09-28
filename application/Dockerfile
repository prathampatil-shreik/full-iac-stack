FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

COPY target/full-iac-stack-app.jar app.jar

ENV APP_ENVIRONMENT=dev
ENV APP_VERSION=1.0.0

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
