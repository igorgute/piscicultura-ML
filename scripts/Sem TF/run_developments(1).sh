#!/bin/bash
# Script para ambiente de desenvolvimento

set -e

echo "Iniciando ambiente de desenvolvimento..."

# Gerar dados
python src/data/collect.py

# Iniciar MLflow em background
mlflow server --backend-store-uri sqlite:///mlflow.db \
    --default-artifact-root ./artifacts \
    --host 0.0.0.0 --port 5000 &
export MLFLOW_TRACKING_URI=http://localhost:5000

# Treinar modelo
python src/train.py

# Iniciar serviços
echo "Iniciando serviços em diferentes terminais..."
echo "1. MLflow: http://localhost:5000"
echo "2. API:    http://localhost:8000"
echo "3. App:    http://localhost:8501"

# Sugerir comandos para rodar em terminais separados
echo -e "\nExecute em terminais separados:"
echo "Terminal 2: uvicorn src.api.app:app --reload --port 8000"
echo "Terminal 3: streamlit run streamlit_app/app.py"
echo -e "\nOu use: ./run_services.sh"