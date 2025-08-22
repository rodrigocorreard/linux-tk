#!/bin/sh

# --- Verifica se a distribuição é baseada em Debian ---
if [ -f /etc/os-release ]; then
    # Carrega as variáveis do arquivo /etc/os-release
    . /etc/os-release
    if [ "$ID" = "debian" ] || echo "$ID_LIKE" | grep -q "debian"; then
        echo "Distribuição compatível detectada: $PRETTY_NAME"
    else
        echo "[erro] Este script é projetado para distribuições baseadas em Debian."
        echo "Distribuição atual: $PRETTY_NAME"
        exit 1
    fi
else
    echo "[aviso] Não foi possível verificar a distribuição. O script continuará, mas pode falhar."
fi

# --- Verifica se o script está sendo executado com privilégios de root ---
if [ "$(id -u)" -ne 0 ]; then
  echo "[erro] Este script precisa ser executado com privilégios de root (ex: sudo ./install_vscode.sh)." >&2
  exit 1
fi

# --- Determina o diretório home e o nome de usuário corretos ---
# Prioriza pkexec, depois sudo, para encontrar o usuário que iniciou o script.
if [ -n "$PKEXEC_UID" ]; then
  USER_HOME=$(getent passwd "$PKEXEC_UID" | cut -d: -f6)
  USER_NAME=$(getent passwd "$PKEXEC_UID" | cut -d: -f1)
elif [ -n "$SUDO_USER" ]; then
  USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
  USER_NAME=$SUDO_USER
else
  # Fallback que não deve ser atingido devido à verificação de root acima.
  USER_HOME=$HOME
  USER_NAME=$USER
fi

# Aborta se não conseguir encontrar o diretório home do usuário.
if [ -z "$USER_HOME" ] || [ -z "$USER_NAME" ]; then
  echo "[erro] Não foi possível determinar o usuário ou o diretório 'home'."
  exit 1
fi

# --- Configura os caminhos e URLs ---
DOWNLOAD_DIR="$USER_HOME/Downloads"
VSCODE_URL="https://vscode.download.prss.microsoft.com/dbazure/download/stable/6f17636121051a53c88d3e605c491d22af2ba755/code_1.103.2-1755709794_amd64.deb"
DOWNLOAD_FILE="vscode_latest_amd64.deb"

echo "O arquivo será baixado em: $DOWNLOAD_DIR"

# Garante que o diretório de Downloads exista, criando-o com o usuário correto.
echo "Verificando se o diretório de downloads existe..."
sudo -u "$USER_NAME" mkdir -p "$DOWNLOAD_DIR"

# Muda para o diretório de Downloads para salvar o arquivo.
cd "$DOWNLOAD_DIR" || { echo "[erro] Não foi possível acessar $DOWNLOAD_DIR"; exit 1; }

echo "Iniciando o download do Visual Studio Code..."
# Usa wget com modo silencioso e barra de progresso.
wget -q --show-progress -c "$VSCODE_URL" -O "$DOWNLOAD_FILE"

if [ $? -ne 0 ]; then
    echo "[erro] O download do Visual Studio Code falhou."
    exit 1
fi

echo "Download concluído com sucesso."

echo "Instalando o pacote .deb..."
# Usa apt-get para instalar o pacote .deb e tratar dependências.
apt-get install -y "./$DOWNLOAD_FILE"

# Verifica se a instalação foi bem-sucedida.
if [ $? -ne 0 ]; then
    echo "[erro] A instalação falhou. Tentando corrigir dependências..."
    apt-get --fix-broken install -y
    # Tenta instalar novamente.
    apt-get install -y "./$DOWNLOAD_FILE"
    if [ $? -ne 0 ]; then
      echo "[erro] A instalação falhou novamente. O arquivo .deb está em $DOWNLOAD_DIR."
      exit 1
    fi
fi

echo "Limpando o arquivo de instalação..."
rm "$DOWNLOAD_FILE"

echo "Visual Studio Code foi instalado com sucesso!"
