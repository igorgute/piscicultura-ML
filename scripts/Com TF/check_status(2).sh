#!/bin/bash
# check_status.sh - Verifica status dos serviços

echo " Verificando status dos serviços..."

# Verificar MLflow
if curl -s http://localhost:5000 > /dev/null; then
    echo " MLflow está rodando: http://localhost:5000"
else
    echo " MLflow não está respondendo"
fi

# Verificar Airflow
if curl -s http://localhost:8080 > /dev/null; then
    echo " Airflow está rodando: http://localhost:8080"
else
    echo " Airflow não está respondendo"
fi

# Verificar arquivos
echo -e "\n Arquivos importantes:"
[ -f "data/synthetic_feed.csv" ] && echo " data/synthetic_feed.csv" || echo " data/synthetic_feed.csv"
[ -f "mlflow.db" ] && echo " mlflow.db" || echo " mlflow.db"
[ -d "artifacts" ] && echo " artifacts/" || echo " artifacts/"

# Verificar processos
echo -e "\n Processos ativos:"
pgrep -f "mlflow" && echo " MLflow processo ativo" || echo " MLflow não está rodando"
docker ps --filter "name=airflow" --format "table {{.Names}}\t{{.Status}}" 2>/dev/null || echo "Docker não disponível"

# Verificar relatório evidently
if [ -f "/tmp/evidently_report.html" ]; then
    echo -e "\n Evidently report: /tmp/evidently_report.html"
    ls -lh "/tmp/evidently_report.html"
fi