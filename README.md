SISTEMA DE GESTÃO INTELIGENTE DE RAÇÃO PARA AQUICULTURA
========================================================

Problema: Um sistema de machine learning de ponta a ponta para otimização do manejo alimentar em tanques de aquicultura. A solução monitora o consumo, prevê a demanda futura e alerta sobre reposições, integrando coleta de dados em tempo real, pipeline automatizado de ML e uma interface de visualização intuitiva.

OBJETIVO
========
Automatizar e otimizar a gestão de ração em tanques de aquicultura, reduzindo desperdícios e garantindo o suprimento adequado através de:
- Monitoramento em tempo real do nível de ração.
- Previsão inteligente do consumo diário.
- Estimativa precisa dos dias restantes até a necessidade de reposição.

ARQUITETURA DO SISTEMA
======================
O sistema é composto por módulos independentes e escaláveis:

Módulo                 Tecnologia                    Função
--------------------- ----------------------------- ---------------------------------------------------------
Coleta de Dados       Raspberry Pi + Sensores       Aquisição contínua de níveis de ração e variáveis ambientais.
Pipeline de Dados     Apache Airflow (DAG)          Orquestração, limpeza e preparação dos dados para análise.
Modelagem Preditiva   Scikit-learn & TensorFlow     Treinamento de modelos para estimativa de consumo e projeção temporal.
Registro de Modelos   MLflow                        Versionamento, rastreabilidade e deploy controlado dos modelos.
API de Inferência     FastAPI (container Lambda)    Serviço escalável para gerar previsões sob demanda.
Monitoramento         Evidently AI                  Detecção de alterações na distribuição dos dados em produção.
Dashboard             Streamlit                     Visualização interativa de métricas, previsões e alertas.

ESTRUTURA DO PROJETO
====================
.
├── data/                 # Datasets (raw & processed)  
├── src/  
│   ├── collection/       # Código para Raspberry Pi  
│   ├── etl/              # DAGs do Airflow  
│   ├── training/         # Scripts de treino (Scikit-learn e TensorFlow)  
│   ├── api/              # FastAPI para inferência  
│   └── monitoring/       # Configurações do Evidently  
├── models/               # Modelos salvos (registrados via MLflow)  
├── notebooks/            # Análises exploratórias e prototipagem  
├── scripts/  
│   ├── Com_TF/  # Pipeline completo com LSTM  
│   └── Sem_TF/      # Versão simplificada (Scikit-learn)  
├── dashboard/            # Aplicação Streamlit  
└── Makefile              # Automação de comandos frequentes  

GUIA DE INICIALIZAÇÃO RÁPIDA
============================

1. PRÉ-REQUISITOS E CONFIGURAÇÃO
---------------------------------
# Clone o repositório
git clone [https://github.com/seu-usuario/gestao-racao-aquicultura.git](https://github.com/igorgute/piscicultura-ML)  
cd gestao-racao-aquicultura

# Execute o script de setup para configurar o ambiente
chmod +x setup.sh

NOTA PARA RASPBERRY PI: Consulte `raspberry_setup.txt` na raiz do projeto para instruções específicas de configuração de hardware e sistema.

2. ESCOLHA DO PIPELINE DE ML
-----------------------------
O sistema oferece duas implementações, balanceando complexidade e desempenho:

- `scripts/Com_TF/`: Pipeline completo com modelo LSTM (TensorFlow) para séries temporais complexas, integrado com monitoramento de drift via Evidently.
- `scripts/Sem_TF/`: Versão simplificada e rápida, utilizando modelos clássicos do Scikit-learn para cenários com padrões mais lineares.

3. EXECUÇÃO
-----------
# Execute o script na raiz
run_all(0)

# OU Navegue até a versão desejada e execute os scripts em ordem
cd scripts/Com_TF   # ou 'Sem_TF'

# Use o Makefile local para executar o pipeline passo a passo (RECOMENDADO)
make run_data_pipeline
make train_model
make deploy_api


RECOMENDAÇÃO: Para maior controle e debugging, execute os passos sequencialmente usando os comandos individuais do `Makefile` em cada pasta.

4. ACESSANDO AS INTERFACES
---------------------------
- Dashboard (Streamlit): http://localhost:8501
- API de Inferência (FastAPI): http://localhost:8000/docs
- MLflow UI (Registro de Modelos): http://localhost:5000

AUTOMAÇÃO COM MAKEFILE
======================
Um `Makefile` principal está disponível na raiz para instalação de dependências essenciais. Cada subpasta (`scripts/Com_TF/` e `scripts/Sem_TF/`) contém seu próprio `Makefile` com comandos específicos do pipeline.

# Na raiz do projeto (instala dependências gerais)
make install_core

# Dentro de uma pasta de script (ex: Sem_TF/)
make help  # Lista todos os comandos disponíveis para aquela versão

ROADMAP E PRÓXIMAS EVOLUÇÕES
============================
1. Unificação de Modelos: Descontinuar a versão exclusiva com Scikit-learn, mantendo o LSTM como modelo principal otimizado.
2. Aplicativo Mobile: Desenvolver um cliente Android/iOS para notificações push e controle remoto.
3. Monitoramento Ampliado: Integrar sensores de qualidade da água (pH, oxigênio, temperatura) e desenvolver módulos de detecção precoce de indicadores de doenças.
4. Sistema de Recomendação: Criar um banco de dados de espécies para recomendar:
   - Dimensionamento do tanque
   - Densidade populacional
   - Necessidade nutricional baseada no comprimento médio dos peixes

LICENÇA
=======
Este projeto é distribuído sob a licença MIT. Consulte o arquivo `LICENSE` para mais informações.

COMO CONTRIBUIR
===============
Contribuições são bem-vindas! Sinta-se à vontade para abrir issues para reportar bugs, sugerir novas funcionalidades ou enviar pull requests.
