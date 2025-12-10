import streamlit as st
import requests

st.title('Beekeep - Estimativa de Ração')

qr = st.number_input('Quantidade de ração (kg)', value=10.0)
np_ = st.number_input('Número de peixes', value=100)
pm = st.number_input('Peso médio (kg)', value=0.3)

if st.button('Calcular'):
    payload = {'qr_kg': qr, 'np': int(np_), 'pm': float(pm)}
    try:
        res = requests.post('http://localhost:8000/predict', json=payload, timeout=5).json()
        st.json(res)
    except Exception as e:
        st.error(str(e))
