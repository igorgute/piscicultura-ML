#!/bin/bash
# Verificação de qualidade e testes

echo " Executando verificações de qualidade..."

# Rodar testes
echo "1. Executando testes..."
pytest -v --cov=src --cov-report=html --cov-report=term

# Linter
echo -e "\n2. Verificando estilo de código..."
flake8 src --count --select=E9,F63,F7,F82 --show-source --statistics
flake8 src --count --exit-zero --max-complexity=10 --max-line-length=127 --statistics

# Type checking (opcional, se usar mypy)
if command -v mypy &> /dev/null; then
    echo -e "\n3. Verificando tipos..."
    mypy src --ignore-missing-imports
fi

# Security check (opcional)
if command -v bandit &> /dev/null; then
    echo -e "\n4. Verificando segurança..."
    bandit -r src -f html -o bandit_report.html 2>/dev/null || true
fi

echo -e "\n Verificações concluídas!"
echo "Relatório de cobertura: file://$(pwd)/htmlcov/index.html"