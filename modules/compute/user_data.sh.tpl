#!/bin/bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Install Docker and AWS CLI
# ---------------------------------------------------------------------------
dnf update -y
dnf install -y docker aws-cli
systemctl enable docker
systemctl start docker

# ---------------------------------------------------------------------------
# Authenticate to ECR and pull the application image
# ---------------------------------------------------------------------------
aws ecr get-login-password --region ${aws_region} \
  | docker login --username AWS --password-stdin ${ecr_registry}

docker pull ${ecr_image_uri}

# ---------------------------------------------------------------------------
# Run the application container
# Restart policy: always — container restarts automatically on failure or reboot
# ---------------------------------------------------------------------------
docker run -d \
  --name full-iac-stack-app \
  --restart always \
  -p ${app_port}:${app_port} \
  -e APP_ENVIRONMENT=${app_environment} \
  -e APP_VERSION=${app_version} \
  ${ecr_image_uri}
