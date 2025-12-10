#!/bin/bash

# run_all.sh - Script completo para executar todo o fluxo
set -e

echo "========================================="
echo "Iniciando fluxo completo de ML"
echo "========================================="

# Função para verificar se comando foi bem sucedido
check_status() {
    if [ $? -eq 0 ]; then
        echo "✓ $1"
    else
        echo "✗ Erro em: $1"
        exit 1
    fi
}

# 1. Gerar dados sintéticos
echo -e "\n[1/8] Gerando dados sintéticos..."
python src/data/collect.py
check_status "Geração de dados sintéticos"
echo "Arquivo gerado: data/synthetic_feed.csv"

# 2. Iniciar MLflow
echo -e "\n[2/8] Iniciando servidor MLflow..."
mlflow server \
    --backend-store-uri sqlite:///mlflow.db \
    --default-artifact-root ./artifacts \
    --host 0.0.0.0 \
    --port 5000 &
MLFLOW_PID=$!

# Esperar MLflow iniciar
sleep 3
export MLFLOW_TRACKING_URI=http://localhost:5000
check_status "MLflow iniciado (PID: $MLFLOW_PID)"
echo "MLflow disponível em: http://localhost:5000"

# 3. Rodar treinamento
echo -e "\n[3/8] Rodando treinamento..."
python src/train.py
check_status "Treinamento"

# 4. Testar API
echo -e "\n[4/8] Iniciando API FastAPI..."
uvicorn src.api.app:app --host 0.0.0.0 --port 8000 --reload &
API_PID=$!
sleep 3

echo "Testando API..."
if [ -f "test_input.json" ]; then
    curl -X POST "http://localhost:8000/predict" \
        -H "Content-Type: application/json" \
        -d @test_input.json
    echo -e "\n"
else
    echo "Arquivo test_input.json não encontrado, criando exemplo..."
    cat > test_input.json << EOF
{
    "features": [1.0, 2.0, 3.0, 4.0, 5.0]
}
EOF
    curl -X POST "http://localhost:8000/predict" \
        -H "Content-Type: application/json" \
        -d @test_input.json
    echo -e "\n"
fi
check_status "API testada"

# 5. Iniciar Streamlit
echo -e "\n[5/8] Iniciando aplicação Streamlit..."
streamlit run streamlit_app/app.py --server.port 8501 &
STREAMLIT_PID=$!
check_status "Streamlit iniciado (PID: $STREAMLIT_PID)"
echo "Streamlit disponível em: http://localhost:8501"

# 6. Rodar testes e qualidade de código
echo -e "\n[6/8] Rodando testes e verificações..."
pytest -q --tb=short
check_status "Testes unitários"

echo "Verificando qualidade de código..."
flake8 src || echo "Aviso: problemas encontrados no linting"

# 7. Deploy AWS (opcional)
echo -e "\n[7/8] Configurar para deploy AWS?"
read -p "Configurar variáveis AWS para deploy? (s/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    export AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID:-123456789012}
    export AWS_REGION=${AWS_REGION:-sa-east-1}
    
    echo "Variáveis AWS configuradas:"
    echo "  AWS_ACCOUNT_ID: $AWS_ACCOUNT_ID"
    echo "  AWS_REGION: $AWS_REGION"
    
    # Tornar script executável e rodar
    if [ -f "scripts/deploy_ecr.sh" ]; then
        chmod +x scripts/deploy_ecr.sh
        ./scripts/deploy_ecr.sh
    else
        echo "Script deploy_ecr.sh não encontrado"
    fi
fi

# 8. Preparar pacote para deploy
echo -e "\n[8/8] Preparando pacote para deploy..."
rm -rf .venv 2>/dev/null || true
rm -rf __pycache__ 2>/dev/null || true
rm -rf .pytest_cache 2>/dev/null || true

echo "Criando arquivo ZIP..."
zip -r beekeep-ml.zip . \
    -x "*.git*" \
    -x "*__pycache__*" \
    -x "*.pytest_cache*" \
    -x "*.venv*" \
    -x "*node_modules*" \
    -x "*.DS_Store*" \
    -x "*.env*" \
    -x "*mlflow.db*" \
    -x "*data/*" \
    -x "*artifacts/*" \
    -x "*logs/*"

check_status "Pacote criado"
echo "Arquivo criado: beekeep-ml.zip ($(du -h beekeep-ml.zip | cut -f1))"

echo -e "\n========================================="
echo "Fluxo completo concluído!"
echo "========================================="
echo -e "\nServiços rodando:"
echo "• MLflow:    http://localhost:5000 (PID: $MLFLOW_PID)"
echo "• API:       http://localhost:8000 (PID: $API_PID)"
echo "• Streamlit: http://localhost:8501 (PID: $STREAMLIT_PID)"
echo -e "\nPara encerrar todos os serviços:"
echo "pkill -P $$"
echo -e "\nPacote para deploy: beekeep-ml.zip"