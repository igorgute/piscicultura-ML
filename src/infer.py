import mlflow
import pandas as pd

MODEL_URI = 'models:/feed_estimator_rf/Production'

class Predictor:
    def __init__(self, model):
        self.model = model

    def predict_and_days(self, input_df):
        cons_pred = self.model.predict(input_df)[0]
        f = cons_pred / (input_df.iloc[0]['np'] * input_df.iloc[0]['pm'])
        D = self.compute_days(input_df.iloc[0]['qr_kg'], input_df.iloc[0]['np'], input_df.iloc[0]['pm'], f)
        return {'consumption_kg_per_day': float(cons_pred), 'f': float(f), 'D_days': float(D)}

    @staticmethod
    def compute_days(qr, np_, pm, f):
        if (np_ * pm * f) <= 0:
            return float('inf')
        return qr / (np_ * pm * f)

_cached_predictor = None

def load_model_and_predict():
    global _cached_predictor
    if _cached_predictor is None:
        model = mlflow.sklearn.load_model(MODEL_URI)
        _cached_predictor = Predictor(model)
    return _cached_predictor
