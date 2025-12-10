#!/bin/bash
# Cria pacote para deploy

echo "Criando pacote para deploy..."

# Limpar
rm -rf .venv meu_venv __pycache__ .pytest_cache *.pyc *.log

# Criar diretório temporário
TEMP_DIR="deploy_package_$(date +%Y%m%d_%H%M%S)"
mkdir -p $TEMP_DIR

# Copiar arquivos necessários
cp -r src $TEMP_DIR/
cp -r streamlit_app $TEMP_DIR/
cp *.py $TEMP_DIR/ 2>/dev/null || true
cp requirements.txt $TEMP_DIR/
cp *.json $TEMP_DIR/ 2>/dev/null || true
cp *.yaml $TEMP_DIR/ 2>/dev/null || true
cp *.yml $TEMP_DIR/ 2>/dev/null || true

# Criar ZIP
cd $TEMP_DIR
zip -r ../beekeep-ml.zip . -x "*.git*" "*__pycache__*" "*.DS_Store*"

cd ..
rm -rf $TEMP_DIR

echo "Pacote criado: beekeep-ml.zip"
echo "Tamanho: $(du -h beekeep-ml.zip | cut -f1)"