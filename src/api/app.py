from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import pandas as pd
import os
from src.infer import load_model_and_predict

app = FastAPI(title="Beekeep Feed Estimator")

class PredictPayload(BaseModel):
    qr_kg: float
    np: int
    pm: float
    temp: float = None
    ph: float = None
    consumption_kg_prev1: float = None
    temp_roll7: float = None

@app.post('/predict')
def predict(payload: PredictPayload):
    try:
        input_df = pd.DataFrame([payload.dict()])
        model = load_model_and_predict()
        res = model.predict_and_days(input_df)
        if res['consumption_kg_per_day'] > payload.qr_kg:
            res['alert'] = 'Quantidade de ração menor que consumo diário'
        else:
            res['alert'] = None
        return res
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
