from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta

default_args = {'owner':'luna','retries':1,'retry_delay':timedelta(minutes=5)}

with DAG('apiculture_pipeline', start_date=datetime(2025,1,1), schedule_interval='@daily', default_args=default_args, catchup=False) as dag:
    collect = BashOperator(
        task_id='collect_data',
        bash_command='python src/data/collect.py'
    )

    train = BashOperator(
        task_id='train_model',
        bash_command='python src/train.py'
    )

    collect >> train
