import pandas as pd

def prepare(df):
    df = df.sort_values('timestamp')
    df['consumption_kg_prev1'] = df['consumption_kg_today'].shift(1).fillna(method='bfill')
    df['temp_roll7'] = df['temp'].rolling(7, min_periods=1).mean()
    df = df.dropna()
    features = ['qr_kg','np','pm','temp','ph','consumption_kg_prev1','temp_roll7']
    return df[features + ['consumption_kg_today']]
