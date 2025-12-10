# Script simplificado de exemplo para Raspberry Pi
import time, requests, os
API_ENDPOINT = os.getenv('API_ENDPOINT', 'http://localhost:8000/predict')
def read_fake():
    # substituir por leitura real do HX711 / DS18B20
    return {'timestamp': time.time(), 'qr_kg': 12.3, 'np': 100, 'pm': 0.3, 'temp':22.0, 'ph':7.0}
def main():
    while True:
        payload = read_fake()
        try:
            r = requests.post(API_ENDPOINT, json=payload, timeout=5)
            print('sent', r.status_code, r.text)
        except Exception as e:
            print('err', e)
        time.sleep(60)
if __name__ == '__main__':
    main()
