#!/bin/bash

# Script de setup automático para ambiente de desenvolvimento/produção
# Pode ser executado com: bash setup.sh

set -e  # Para em caso de erro

echo "========================================="
echo "Iniciando setup do ambiente..."
echo "========================================="

# 1. Atualizar sistema
echo -e "\n[1/7] Atualizando sistema..."
sudo apt update && sudo apt upgrade -y

# 2. Instalar dependências mínimas
echo -e "\n[2/7] Instalando dependências..."
sudo apt install -y python3 python3-venv python3-pip docker.io docker-compose git

# 3. Clonar repositório (com opção)
echo -e "\n[3/7] Verificando repositório..."
read -p "Deseja clonar o repositório? (s/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    git clone https://github.com/igorgute/piscicultura-ML
    cd piscicultura-ML
    echo "Repositório clonado e diretório alterado."
else
    echo "Pulando clone. Certifique-se de estar no diretório correto."
fi

# 4. Criar e ativar venv
echo -e "\n[4/7] Criando ambiente virtual..."
python3 -m venv .venv
source .venv/bin/activate

# 5. Instalar dependências do projeto
echo -e "\n[5/7] Instalando dependências Python..."
pip install --upgrade pip

if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
else
    echo "AVISO: requirements.txt não encontrado!"
    read -p "Deseja instalar dependências básicas? (s/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        pip install numpy pandas scikit-learn matplotlib seaborn jupyter
    fi
fi

# 6. Criar diretórios necessários
echo -e "\n[6/7] Criando diretórios..."
mkdir -p data
mkdir -p artifacts
mkdir -p logs

# 7. Verificar instalação
echo -e "\n[7/7] Verificando instalações..."
echo "Python: $(python3 --version)"
echo "Pip: $(pip --version)"
echo "Docker: $(docker --version)"
echo "Docker Compose: $(docker-compose --version)"

echo -e "\n========================================="
echo "Setup concluído com sucesso!"
echo "========================================="
echo -e "\nPróximos passos:"
echo "1. Ambiente virtual ativado automaticamente"
echo "2. Para reativar manualmente: source .venv/bin/activate"
echo "3. Diretórios criados: data/, artifacts/, logs/"
echo -e "\nPara desativar o ambiente virtual: deactivate"