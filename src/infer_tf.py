import mlflow
import numpy as np
import pandas as pd
import joblib
import io

TF_MODEL_URI = 'models:/feed_estimator_tf/Production'

def load_tf_model_and_scaler(model_uri=TF_MODEL_URI, mlflow_uri=None):
    if mlflow_uri:
        mlflow.set_tracking_uri(mlflow_uri)
    # Carregar modelo TensorFlow registrado no MLflow
    model = mlflow.tensorflow.load_model(model_uri)
    # tentar carregar scaler dos artifacts da última execução (usuário pode modificar para apontar execução exata)
    client = mlflow.tracking.MlflowClient()
    # encontrar a última versão do modelo registrado
    try:
        mv = client.get_latest_versions('feed_estimator_tf', stages=['Production'])
        if mv:
            run_id = mv[0].run_id
            # baixar artifact scaler
            scaler_art = client.download_artifacts(run_id, 'preprocessing/scaler.pkl', dst_path='artifacts_tmp')
            scaler = joblib.load(scaler_art)
        else:
            scaler = None
    except Exception:
        scaler = None
    return model, scaler

def prepare_sequence(df_prepared, scaler, seq_len=14):
    arr = df_prepared.drop(columns=['consumption_kg_today']).values
    if scaler is not None:
        arr = scaler.transform(arr)
    last_seq = arr[-seq_len:]
    return last_seq.reshape((1, last_seq.shape[0], last_seq.shape[1]))
