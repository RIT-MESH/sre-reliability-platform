#!/bin/bash
set -euo pipefail
# User-data: installs Docker, pulls the app image and runs it.
# Secrets are NOT embedded here; the app reads them at runtime via IAM/SSM.
exec > >(tee -a /var/log/user-data.log) 2>&1
echo "[user-data] starting at $(date -u +%Y-%m-%dT%H:%M:%SZ)"

# --- Install Docker on Amazon Linux 2023 ---
dnf -y update
dnf -y install docker
systemctl enable --now docker

# --- Install the CloudWatch agent for system metrics/logs ---
dnf -y install amazon-cloudwatch-agent

# --- Pull and run the application ---
APP_PORT=${app_port}
ECR_IMAGE=${ecr_image}
ENVIRONMENT=${environment}
WORKERS=${workers}
DB_HOST=${db_host}
DB_SECRET_ARN=${db_secret_arn}
REDIS_HOST=${redis_host}

aws ecr get-login-password --region "$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | cut -d'"' -f4)" | docker login --username AWS --password-stdin "$(echo "$ECR_IMAGE" | cut -d'.' -f1)"

docker pull "$ECR_IMAGE"
docker run -d \
  --name app \
  --restart unless-stopped \
  -p 127.0.0.1:$APP_PORT:$APP_PORT \
  -e PORT=$APP_PORT \
  -e ENVIRONMENT=$ENVIRONMENT \
  -e WORKERS=$WORKERS \
  -e DB_SECRET_ARN=$DB_SECRET_ARN \
  -e REDIS_URL="redis://$REDIS_HOST:6379/0" \
  -e DATABASE_HOST=$DB_HOST \
  --log-driver=awslogs \
  --log-opt awslogs-group=/aws/ec2/sre-platform-$ENVIRONMENT \
  --log-opt awslogs-stream-prefix=app \
  "$ECR_IMAGE"

echo "[user-data] done at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
