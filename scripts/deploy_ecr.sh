#!/usr/bin/env bash
set -e
if [ -z "$AWS_ACCOUNT_ID" ]; then
  echo "Set AWS_ACCOUNT_ID environment variable"
  exit 1
fi
if [ -z "$AWS_REGION" ]; then
  echo "Set AWS_REGION environment variable (ex: sa-east-1)"
  exit 1
fi
REPO_NAME=beekeep-ml-lambda
IMAGE_TAG=${IMAGE_TAG:-$(git rev-parse --short HEAD)}
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG}"
aws ecr describe-repositories --repository-names "$REPO_NAME" --region "$AWS_REGION" >/dev/null 2>&1 ||       aws ecr create-repository --repository-name "$REPO_NAME" --region "$AWS_REGION"
echo "Building image..."
docker build -t ${REPO_NAME}:${IMAGE_TAG} -f Dockerfile.lambda .
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
docker tag ${REPO_NAME}:${IMAGE_TAG} ${ECR_URI}
docker push ${ECR_URI}
echo "Pushed ${ECR_URI}"
