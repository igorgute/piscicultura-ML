#!/bin/bash

# setup_and_run.sh - Script completo para setup, treinamento e teste
set -e

# Configurações
VENV_DIR=".venv"
MLFLOW_PORT=5000
AIRFLOW_COMPOSE="docker-compose-airflow.yaml"
EVIDENTLY_REPORT="/tmp/evidently_report.html"

echo "========================================="
echo " Iniciando Setup e Pipeline Completo"
echo "========================================="

# Função para verificar status
check_status() {
    if [ $? -eq 0 ]; then
        echo " $1"
    else
        echo " Falha em: $1"
        exit 1
    fi
}

# 1. Criar e ativar ambiente virtual
echo -e "\n[1/10] Configurando ambiente virtual..."
if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv $VENV_DIR
    check_status "Ambiente virtual criado"
else
    echo "Ambiente virtual já existe, reutilizando..."
fi

# Ativar venv
source $VENV_DIR/bin/activate
check_status "Ambiente virtual ativado"

# 2. Instalar dependências
echo -e "\n[2/10] Instalando dependências..."
pip install --upgrade pip
check_status "Pip atualizado"

if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
    check_status "Dependências instaladas"
else
    echo "AVISO: requirements.txt não encontrado!"
    read -p "Instalar dependências básicas? (s/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        pip install mlflow pandas numpy scikit-learn tensorflow evidently
        check_status "Dependências básicas instaladas"
    else
        echo "Continuando sem instalar dependências..."
    fi
fi

# 3. Criar diretórios necessários
echo -e "\n[3/10] Criando diretórios..."
mkdir -p data
mkdir -p artifacts
mkdir -p logs
mkdir -p airflow_dags
check_status "Diretórios criados"

# 4. Gerar dados sintéticos
echo -e "\n[4/10] Gerando dados sintéticos..."
python src/data/collect.py
check_status "Dados sintéticos gerados"
echo "Arquivo: $(ls -la data/synthetic_feed.csv)"

# 5. Iniciar MLflow
echo -e "\n[5/10] Iniciando servidor MLflow..."
# Parar MLflow se já estiver rodando na porta
lsof -ti:$MLFLOW_PORT | xargs kill -9 2>/dev/null || true

mlflow server \
    --backend-store-uri sqlite:///mlflow.db \
    --default-artifact-root ./artifacts \
    --host 0.0.0.0 \
    --port $MLFLOW_PORT > logs/mlflow.log 2>&1 &
MLFLOW_PID=$!

# Aguardar inicialização
sleep 5
export MLFLOW_TRACKING_URI=http://localhost:$MLFLOW_PORT
check_status "MLflow iniciado (PID: $MLFLOW_PID)"
echo "MLflow UI: http://localhost:$MLFLOW_PORT"

# 6. Treinar modelo TensorFlow
echo -e "\n[6/10] Treinando modelo TensorFlow..."
# Garantir que venv está ativado
source $VENV_DIR/bin/activate
python src/train_tf.py
check_status "Modelo TensorFlow treinado"

# 7. Verificar modelo no MLflow
echo -e "\n[7/10] Verificando modelo no MLflow..."
sleep 3
echo "Verifique manualmente: http://localhost:$MLFLOW_PORT"
echo "Procure por 'feed_estimator_tf'"

# 8. Testar inferência local
echo -e "\n[8/10] Testando inferência local..."
python - <<'PY'
import pandas as pd
import joblib
import sys

try:
    from src.data.prepare import prepare
    from src.infer_tf import load_tf_model_and_scaler, prepare_sequence
    
    print("Carregando dados...")
    df = pd.read_csv('data/synthetic_feed.csv', parse_dates=['timestamp'])
    
    print("Preparando dados...")
    dfp = prepare(df)
    
    print("Carregando modelo e scaler...")
    model, scaler = load_tf_model_and_scaler()
    
    print("Preparando sequência...")
    seq = prepare_sequence(dfp, scaler, seq_len=14)
    
    print("Fazendo predição...")
    pred = model.predict(seq)
    
    result = pred.flatten()[0]
    print(f" Consumo previsto (kg/dia): {result:.4f}")
    
    # Salvar resultado
    with open('logs/prediction.log', 'w') as f:
        f.write(f"Prediction: {result:.4f}\n")
        
except Exception as e:
    print(f" Erro na inferência: {e}")
    sys.exit(1)
PY
check_status "Inferência testada"

# 9. Executar monitoramento Evidently
echo -e "\n[9/10] Executando monitoramento Evidently..."
python -c "
try:
    from airflow_dags.dag_monitoring_evidently import run_evidently
    run_evidently()
    print(' Relatório Evidently gerado com sucesso')
except ImportError as e:
    print(f'  Módulo não encontrado: {e}')
    print('Criando exemplo de relatório...')
    # Criar relatório de exemplo se o módulo não existir
    import pandas as pd
    from evidently.report import Report
    from evidently.metrics import DatasetSummaryMetric
    
    df = pd.read_csv('data/synthetic_feed.csv')
    report = Report(metrics=[DatasetSummaryMetric()])
    report.run(current_data=df, reference_data=None)
    report.save_html('$EVIDENTLY_REPORT')
    print('Relatório de exemplo criado')
except Exception as e:
    print(f' Erro no Evidently: {e}')
"

# Verificar relatório
if [ -f "$EVIDENTLY_REPORT" ]; then
    echo "Relatório Evidently: $EVIDENTLY_REPORT"
    ls -l "$EVIDENTLY_REPORT"
else
    # Tentar local alternativo
    if [ -f "logs/evidently_report.html" ]; then
        echo "Relatório encontrado em: logs/evidently_report.html"
        ls -l logs/evidently_report.html
    else
        echo "  Relatório Evidently não encontrado"
    fi
fi

# 10. Iniciar Airflow
echo -e "\n[10/10] Configurando Airflow..."
if [ -f "$AIRFLOW_COMPOSE" ]; then
    echo "Iniciando Airflow com Docker Compose..."
    docker-compose -f "$AIRFLOW_COMPOSE" down 2>/dev/null || true
    docker-compose -f "$AIRFLOW_COMPOSE" up -d
    check_status "Airflow iniciado"
    
    echo "Aguardando inicialização do Airflow..."
    sleep 10
    echo "Airflow UI disponível em: http://localhost:8080"
    
    # Copiar DAGs se existirem
    if [ -d "airflow_dags" ] && [ ! -z "$(ls -A airflow_dags/ 2>/dev/null)" ]; then
        echo "Copiando DAGs para container Airflow..."
        DAG_CONTAINER=$(docker-compose -f "$AIRFLOW_COMPOSE" ps -q airflow-webserver 2>/dev/null || echo "")
        if [ ! -z "$DAG_CONTAINER" ]; then
            docker cp airflow_dags/ $DAG_CONTAINER:/opt/airflow/dags/
            echo "DAGs copiados"
        fi
    fi
else
    echo "  $AIRFLOW_COMPOSE não encontrado"
    echo "Criando docker-compose de exemplo..."
    
    cat > docker-compose-airflow.yaml << 'EOF'
version: '3.8'
services:
  postgres:
    image: postgres:13
    environment:
      POSTGRES_USER: airflow
      POSTGRES_PASSWORD: airflow
      POSTGRES_DB: airflow
    volumes:
      - postgres-db-volume:/var/lib/postgresql/data

  airflow-webserver:
    image: apache/airflow:2.5.1
    depends_on:
      - postgres
    environment:
      AIRFLOW__DATABASE__SQL_ALCHEMY_CONN: postgresql+psycopg2://airflow:airflow@postgres/airflow
      AIRFLOW__CORE__EXECUTOR: LocalExecutor
      AIRFLOW__CORE__LOAD_EXAMPLES: 'false'
    volumes:
      - ./airflow_dags:/opt/airflow/dags
      - ./logs:/opt/airflow/logs
    ports:
      - "8080:8080"
    command: webserver

volumes:
  postgres-db-volume:
EOF
    
    echo "Arquivo docker-compose-airflow.yaml criado"
    read -p "Deseja iniciar o Airflow agora? (s/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        docker-compose -f "$AIRFLOW_COMPOSE" up -d
        echo "Airflow iniciado em: http://localhost:8080"
    fi
fi

echo -e "\n========================================="
echo " Pipeline executado com sucesso!"
echo "========================================="
echo -e "\n Serviços disponíveis:"
echo "• MLflow:      http://localhost:$MLFLOW_PORT"
echo "• Airflow UI:  http://localhost:8080"
echo "• Evidently:   $EVIDENTLY_REPORT"
echo -e "\n📁 Arquivos gerados:"
echo "• Dados:       data/synthetic_feed.csv"
echo "• Artefatos:   artifacts/"
echo "• Logs:        logs/"
echo -e "\n Para ver logs do MLflow:"
echo "  tail -f logs/mlflow.log"
echo -e "\n Para parar serviços:"
echo "  pkill -f mlflow"
echo "  docker-compose -f $AIRFLOW_COMPOSE down"
echo -e "\n Próximos passos:"
echo "1. Verifique o modelo em: http://localhost:$MLFLOW_PORT"
echo "2. Configure seus DAGs em: airflow_dags/"
echo "3. Acesse o Airflow em: http://localhost:8080"
echo "   (usuário: airflow, senha: airflow)"