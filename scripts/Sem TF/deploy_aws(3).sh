#!/bin/bash
# Script para deploy na AWS

set -e

echo "Configurando deploy AWS..."

# Verificar variáveis
if [ -z "$AWS_ACCOUNT_ID" ] || [ -z "$AWS_REGION" ]; then
    echo "Configurando variáveis AWS..."
    export AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID:-123456789012}
    export AWS_REGION=${AWS_REGION:-sa-east-1}
    
    echo "AWS_ACCOUNT_ID: $AWS_ACCOUNT_ID"
    echo "AWS_REGION: $AWS_REGION"
fi

# Login no ECR
echo "📦 Fazendo login no ECR..."
aws ecr get-login-password --region $AWS_REGION | \
    docker login --username AWS --password-stdin \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Rodar script de deploy
if [ -f "scripts/deploy_ecr.sh" ]; then
    echo "Executando deploy..."
    chmod +x scripts/deploy_ecr.sh
    ./scripts/deploy_ecr.sh
else
    echo "Criando script de deploy básico..."
    
    # Criar imagem Docker
    docker build -t beekeep-ml .
    
    # Taggear imagem
    SHORT_COMMIT=$(git rev-parse --short HEAD)
    IMAGE_URI=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/beekeep-ml:$SHORT_COMMIT
    docker tag beekeep-ml:latest $IMAGE_URI
    
    # Push para ECR
    docker push $IMAGE_URI
    
    echo "Imagem pushada: $IMAGE_URI"
fi

# Criar/atualizar Lambda
echo "λ Configurando Lambda..."
IMAGE_URI=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/beekeep-ml:$(git rev-parse --short HEAD)

# Verificar se função existe
if aws lambda get-function --function-name beekeep-ml 2>/dev/null; then
    echo "Atualizando função Lambda..."
    aws lambda update-function-code \
        --function-name beekeep-ml \
        --image-uri $IMAGE_URI
else
    echo "Criando nova função Lambda..."
    aws lambda create-function \
        --function-name beekeep-ml \
        --package-type Image \
        --code ImageUri=$IMAGE_URI \
        --role arn:aws:iam::${AWS_ACCOUNT_ID}:role/LambdaExecutionRole \
        --timeout 30 \
        --memory-size 512
fi

echo "Deploy AWS concluído!"