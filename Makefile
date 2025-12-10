.PHONY: init install train run-api run-api-uv deploy-ecr mlflow-up airflow-up streamlit test lint

init: install

install:
	python3 -m venv .venv
	. .venv/bin/activate && pip install --upgrade pip
	. .venv/bin/activate && pip install -r requirements.txt

train:
	. .venv/bin/activate && python src/train.py

run-api:
	. .venv/bin/activate && uvicorn src.api.app:app --reload --port 8000

run-api-uv:
	uvicorn src.api.app:app --host 0.0.0.0 --port 8000

mlflow-up:
	mlflow server --backend-store-uri sqlite:///mlflow.db --default-artifact-root ./artifacts -p 5000

airflow-up:
	docker-compose -f docker-compose-airflow.yaml up -d

streamlit:
	. .venv/bin/activate && streamlit run streamlit_app/app.py

deploy-ecr:
	bash scripts/deploy_ecr.sh
