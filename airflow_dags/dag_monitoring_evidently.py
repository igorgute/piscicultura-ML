from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta
import pandas as pd
import os
from evidently.profile import Profile
from evidently.profile.sections import DataDriftProfileSection
from evidently.dashboard import Dashboard
from evidently.dashboard.tabs import DataDriftTab

DEFAULT_ARGS = {'owner':'luna','retries':1,'retry_delay':timedelta(minutes=5)}

def run_evidently(**kwargs):
    # reference dataset should be stored under mlflow/artifacts or data/reference.csv
    ref_path = os.getenv('EVIDENTLY_REFERENCE', 'data/synthetic_feed.csv')
    curr_path = os.getenv('EVIDENTLY_CURRENT', 'data/synthetic_feed.csv')
    ref = pd.read_csv(ref_path, parse_dates=['timestamp'])
    curr = pd.read_csv(curr_path, parse_dates=['timestamp'])

    profile = Profile(sections=[DataDriftProfileSection()])
    profile.calculate(ref, curr)
    out_html = '/tmp/evidently_report.html'
    profile.save_html(out_html)
    print('Evidently report saved to', out_html)
    # In production, you would upload report to S3 and notify via Slack/email

with DAG('evidently_monitoring', start_date=datetime(2025,1,1), schedule_interval='@daily', default_args=DEFAULT_ARGS, catchup=False) as dag:
    monitor = PythonOperator(task_id='run_evidently', python_callable=run_evidently, provide_context=True)
