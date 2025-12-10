import mlflow
import mlflow.sklearn
import pandas as pd
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_error, r2_score
from src.data.prepare import prepare

def train(data_path='data/synthetic_feed.csv', mlflow_uri=None):
    if mlflow_uri:
        mlflow.set_tracking_uri(mlflow_uri)
    mlflow.set_experiment('apicultura-feed-estimator')
    df = pd.read_csv(data_path, parse_dates=['timestamp'])
    dfp = prepare(df)
    X = dfp.drop(columns=['consumption_kg_today'])
    y = dfp['consumption_kg_today']
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    with mlflow.start_run():
        model = RandomForestRegressor(n_estimators=100, random_state=42)
        model.fit(X_train, y_train)
        preds = model.predict(X_test)
        mae = mean_absolute_error(y_test, preds)
        r2 = r2_score(y_test, preds)
        mlflow.log_metric('mae', mae)
        mlflow.log_metric('r2', r2)
        mlflow.sklearn.log_model(model, 'model', registered_model_name='feed_estimator_rf')
        print('MAE:', mae, 'R2:', r2)

if __name__ == '__main__':
    train()
