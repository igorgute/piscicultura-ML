import pandas as pd
import numpy as np
from datetime import datetime, timedelta

def generate_synthetic(n_days=365, seed=42):
    np.random.seed(seed)
    rows=[]
    base_date = datetime.now()
    for i in range(n_days):
        ts = base_date - timedelta(days=n_days-i)
        temp = 20 + 5*np.sin(i/30) + np.random.normal(0, 0.8)
        ph = 7 + 0.2*np.random.normal()
        np_fish = 100 + np.random.randint(-5, 6)
        pm = 0.3 + 0.02*np.random.normal()
        f = 0.02 + 0.001*max(0, temp-22) + np.random.normal(0, 0.002)
        consumption_kg_today = np_fish * pm * f
        qr_kg = max(5.0, 20 + np.random.normal(0,2))
        rows.append({
            "timestamp": ts,
            "qr_kg": round(qr_kg,3),
            "np": np_fish,
            "pm": round(pm,4),
            "temp": round(temp,2),
            "ph": round(ph,2),
            "consumption_kg_today": round(consumption_kg_today,4),
            "f": round(f,6)
        })
    df = pd.DataFrame(rows)
    return df

if __name__ == '__main__':
    df = generate_synthetic()
    df.to_csv('data/synthetic_feed.csv', index=False)
    print('Saved data/synthetic_feed.csv')
