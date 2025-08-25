#!/bin/bash

# Este script instala o NVM (Node Version Manager) e a versão LTS mais recente do Node.js.
# Ele foi projetado para ser executado como um usuário normal, não como root.

# --- Evita a execução com sudo ---
if [ "$(id -u)" -eq 0 ]; then
  echo "[erro] Este script deve ser executado como um usuário normal, sem usar 'sudo'." >&2
  exit 1
fi

echo "Iniciando a instalação do NVM (Node Version Manager)..."

# Define a versão do NVM a ser instalada para garantir consistência.
# Você pode atualizar este número para uma versão mais recente, se necessário.
NVM_VERSION="v0.40.3"
INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh"

# --- Baixa e executa o script de instalação oficial do NVM ---
# O script de instalação modifica os arquivos de perfil do shell (ex: .bashrc, .zshrc)
# para carregar o NVM automaticamente em novas sessões de terminal.
wget -qO- "$INSTALL_URL" | bash

if [ $? -ne 0 ]; then
    echo "[erro] A instalação do NVM falhou."
    exit 1
fi

echo "Script de instalação do NVM executado com sucesso."
echo "Configurando o ambiente para usar o NVM na sessão atual..."

# --- Carrega o NVM na sessão atual ---
# O comando a seguir é crucial, pois torna o 'nvm' disponível imediatamente.
# Sem ele, você precisaria iniciar um novo terminal para usar o NVM.
export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

echo "NVM carregado. Instalando a versão LTS (Long-Term Support) mais recente do Node.js..."

# --- Instala e usa a versão LTS do Node.js ---
nvm install --lts
nvm use --lts
nvm alias default 'lts/*'

# --- Exibe a confirmação final ---
echo ""
echo "-------------------------------------------------"
echo "NVM e Node.js instalados com sucesso!"
echo ""
echo "Versões instaladas:"
echo "NVM:  $(nvm --version)"
echo "Node: $(node --version)"
echo "NPM:  $(npm --version)"
echo "-------------------------------------------------"
echo ""
echo "Para garantir que o NVM esteja sempre disponível, por favor, feche e reabra seu terminal,"
echo "ou execute o comando: source ~/.bashrc (ou ~/.zshrc, etc.)"
echo "-------------------------------------------------"
