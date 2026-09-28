# full-iac-stack-app

A lightweight Spring Boot REST application built as the application layer of a complete Infrastructure-as-Code stack. The infrastructure (VPC, EC2, ALB, RDS, etc.) will be provisioned separately using Terraform on AWS.

---

## Technology Stack

| Component | Version |
|-----------|---------|
| Java | 17 |
| Spring Boot | 3.2.5 |
| Build Tool | Maven |
| Container | Docker (eclipse-temurin:17-jre-alpine) |

---

## Project Structure

```
application/
├── pom.xml
├── Dockerfile
├── .dockerignore
├── README.md
└── src/
    ├── main/
    │   ├── java/com/fulliac/app/
    │   │   ├── FullIacStackApplication.java
    │   │   ├── controller/
    │   │   │   └── ApplicationController.java
    │   │   └── model/
    │   │       └── HealthResponse.java
    │   └── resources/
    │       └── application.properties
    └── test/
        └── java/com/fulliac/app/controller/
            └── ApplicationControllerTest.java
```

---

## Prerequisites

- Java 17+
- Maven 3.8+
- Docker (for container builds)

---

## Maven Build

```bash
mvn clean package
```

Produces: `target/full-iac-stack-app.jar`

---

## Running Locally

```bash
java -jar target/full-iac-stack-app.jar
```

With custom environment variables:

```bash
APP_ENVIRONMENT=dev APP_VERSION=1.0.0 java -jar target/full-iac-stack-app.jar
```

---

## Running Tests

```bash
mvn test
```

---

## Available REST Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Application root info |
| GET | `/health` | ALB health check endpoint |
| GET | `/api/info` | Application and runtime info |
| GET | `/actuator/health` | Spring Boot Actuator health |
| GET | `/actuator/info` | Spring Boot Actuator info |

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `APP_ENVIRONMENT` | `local` | Deployment environment (local, dev, prod) |
| `APP_VERSION` | `1.0.0` | Application version |

---

## Docker Build

```bash
docker build -t full-iac-stack-app:1.0.0 .
```

## Docker Run

```bash
docker run --name full-iac-stack-app -p 8080:8080 \
  -e APP_ENVIRONMENT=local \
  -e APP_VERSION=1.0.0 \
  full-iac-stack-app:1.0.0
```

---

## Test All Endpoints

```bash
curl http://localhost:8080/
curl http://localhost:8080/health
curl http://localhost:8080/api/info
curl http://localhost:8080/actuator/health
```

---

## Health Check

The `/health` endpoint is used by the AWS Application Load Balancer:

- Returns HTTP `200`
- Returns `{ "status": "healthy" }`
- Has no external dependencies (no database required)

---

## Troubleshooting

**Port already in use:**
```bash
# Change port via environment variable
SERVER_PORT=9090 java -jar target/full-iac-stack-app.jar
```

**Docker container already exists:**
```bash
docker rm -f full-iac-stack-app
docker run --name full-iac-stack-app -p 8080:8080 full-iac-stack-app:1.0.0
```

**JAR not found during Docker build:**
```bash
# Always run Maven build before Docker build
mvn clean package
docker build -t full-iac-stack-app:1.0.0 .
```
