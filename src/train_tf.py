import mlflow
import mlflow.tensorflow
import pandas as pd
import numpy as np
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import LSTM, Dense, Dropout
from tensorflow.keras.callbacks import EarlyStopping
from src.data.prepare import prepare
import joblib
import os

def create_sequences(X, y, seq_len=14):
    Xs, ys = [], []
    for i in range(seq_len, len(X)):
        Xs.append(X[i-seq_len:i])
        ys.append(y[i])
    return np.array(Xs), np.array(ys)

def build_model(input_shape):
    model = Sequential()
    model.add(LSTM(64, input_shape=input_shape, return_sequences=True))
    model.add(Dropout(0.2))
    model.add(LSTM(32))
    model.add(Dropout(0.2))
    model.add(Dense(1))
    model.compile(optimizer='adam', loss='mae', metrics=['mae'])
    return model

def train_tf(data_path='data/synthetic_feed.csv', mlflow_uri=None, seq_len=14, epochs=30, batch_size=32):
    if mlflow_uri:
        mlflow.set_tracking_uri(mlflow_uri)
    mlflow.set_experiment('apicultura-feed-estimator-tf')

    df = pd.read_csv(data_path, parse_dates=['timestamp'])
    dfp = prepare(df)
    features = dfp.drop(columns=['consumption_kg_today']).values
    target = dfp['consumption_kg_today'].values

    scaler = StandardScaler()
    features_scaled = scaler.fit_transform(features)

    X_seq, y_seq = create_sequences(features_scaled, target, seq_len=seq_len)
    if len(X_seq) == 0:
        raise ValueError('Não ha dados o suficiente. Insira mais dados ou reduza o seq_len.')

    X_train, X_val, y_train, y_val = train_test_split(X_seq, y_seq, test_size=0.2, random_state=42)

    model = build_model(input_shape=(X_train.shape[1], X_train.shape[2]))
    es = EarlyStopping(patience=7, restore_best_weights=True)

    with mlflow.start_run():
        mlflow.log_param('seq_len', seq_len)
        mlflow.log_param('epochs', epochs)
        mlflow.log_param('batch_size', batch_size)

        history = model.fit(X_train, y_train, validation_data=(X_val, y_val),
                            epochs=epochs, batch_size=batch_size, callbacks=[es], verbose=2)

        val_mae = float(min(history.history.get('val_mae', [0])))
        mlflow.log_metric('val_mae', val_mae)

        # Salvar o scaler e gerar log como artifact para inferência
        os.makedirs('artifacts', exist_ok=True)
        scaler_path = os.path.join('artifacts', 'scaler.pkl')
        joblib.dump(scaler, scaler_path)
        mlflow.log_artifact(scaler_path, artifact_path='preprocessing')

        # Registrar o modelo tensorflow
        mlflow.tensorflow.log_model(tf_model=model, artifact_path='model', registered_model_name='feed_estimator_tf')

        print('Training finished. Val MAE:', val_mae)

if __name__ == '__main__':
    train_tf()
