#!/bin/bash
# Inicia todos os serviços em background

# Iniciar MLflow
mlflow server --backend-store-uri sqlite:///mlflow.db \
    --default-artifact-root ./artifacts \
    --host 0.0.0.0 --port 5000 > mlflow.log 2>&1 &
echo "MLflow iniciado (http://localhost:5000)"

# Iniciar API
uvicorn src.api.app:app --host 0.0.0.0 --port 8000 > api.log 2>&1 &
echo "API iniciada (http://localhost:8000)"

# Iniciar Streamlit
streamlit run streamlit_app/app.py --server.port 8501 > streamlit.log 2>&1 &
echo "Streamlit iniciado (http://localhost:8501)"

# Exportar variáveis
export MLFLOW_TRACKING_URI=http://localhost:5000

echo -e "\nServiços rodando em background:"
echo "• MLflow:    PID $! (logs: mlflow.log)"
echo "• API:       PID $! (logs: api.log)"
echo "• Streamlit: PID $! (logs: streamlit.log)"

echo -e "\nPara parar todos: pkill -f 'mlflow\|uvicorn\|streamlit'"
echo -e "\nPara ver logs: tail -f *.log"