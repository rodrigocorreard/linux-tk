#!/bin/bash

# --- Determina o diretório home e o nome de usuário corretos ---
# Funciona mesmo quando executado com 'sudo' ou 'pkexec'.
if [ -n "$SUDO_USER" ]; then
    USER_NAME=$SUDO_USER
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
elif [ -n "$PKEXEC_UID" ]; then
    USER_NAME=$(getent passwd "$PKEXEC_UID" | cut -d: -f1)
    USER_HOME=$(getent passwd "$PKEXEC_UID" | cut -d: -f6)
else
    # Fallback para execução normal
    USER_NAME=$USER
    USER_HOME=$HOME
fi

# Aborta se não conseguir encontrar o diretório home do usuário
if [ -z "$USER_HOME" ] || [ -z "$USER_NAME" ]; then
  echo "[erro] Não foi possível determinar o usuário ou o diretório 'home'."
  exit 1
fi

# --- Verificação de dependências ---
echo "Sua senha poderá ser exigida várias vezes"
echo "Verificando dependências (curl, unzip)..."
for cmd in curl unzip; do
  if ! command -v $cmd &> /dev/null; then
    echo "O comando '$cmd' não foi encontrado. Tentando instalar..."
    # Atualiza a lista de pacotes e instala a dependência
    pkexec apt-get update && pkexec apt-get install -y $cmd
    if [ $? -ne 0 ]; then
        echo "[erro] Falha ao instalar '$cmd'. Por favor, instale-o manualmente e tente novamente."
        exit 1
    fi
  fi
done


DOWNLOAD_DIR="$USER_HOME/Downloads"
FTP_HOST="82.180.153.44"
FTP_USER_B64="dTU0NDYzNjk0OS5EYXZpbmNp"
FTP_PASS_B64="RGF2aW5jaTIwXzE="
FTP_USER=$(echo "$FTP_USER_B64" | base64 --decode)
FTP_PASS=$(echo "$FTP_PASS_B64" | base64 --decode)


REMOTE_FILE="davinci_resolve_20.1_linux.zip"
LOCAL_FILE="$DOWNLOAD_DIR/$REMOTE_FILE"

echo "Diretório de destino: $DOWNLOAD_DIR"

# Garante que a pasta de Downloads exista
sudo -u "$USER_NAME" mkdir -p "$DOWNLOAD_DIR"

# Muda para o diretório de Downloads para trabalhar
cd "$DOWNLOAD_DIR" || { echo "[erro] Não foi possível acessar $DOWNLOAD_DIR"; exit 1; }

echo "Iniciando o download do DaVinci Resolve..."
# Usa curl para baixar o arquivo do servidor FTP
curl -u "$FTP_USER:$FTP_PASS" "ftp://$FTP_HOST/$REMOTE_FILE" -o "$LOCAL_FILE" --progress-bar

if [ $? -ne 0 ]; then
    echo "[erro] O download falhou. Verifique o nome do arquivo, as credenciais e sua conexão com a internet."
    exit 1
fi

echo "Download concluído com sucesso. Extraindo o arquivo..."
# Extrai o arquivo .zip como o usuário correto
sudo -u "$USER_NAME" unzip -o "$LOCAL_FILE"
if [ $? -ne 0 ]; then
    echo "[erro] A extração do arquivo falhou."
    rm "$LOCAL_FILE"
    exit 1
fi

# Procura pelo instalador .run que foi extraído
INSTALLER_RUN=$(find . -maxdepth 1 -type f -name "*.run")

if [ -z "$INSTALLER_RUN" ]; then
    echo "[erro] Nenhum arquivo de instalação (.run) foi encontrado nos arquivos extraídos."
    rm "$LOCAL_FILE"
    exit 1
fi

echo "Instalador encontrado: $INSTALLER_RUN"
echo "Tornando o instalador executável..."
chmod +x "$INSTALLER_RUN"

echo "Iniciando a instalação do DaVinci Resolve. Siga as instruções na tela."
# O instalador do DaVinci nao requer interação e privilégios de administrador
SKIP_PACKAGE_CHECK=1 ./"$INSTALLER_RUN"
INSTALL_STATUS=$?

pkexec mkdir /opt/resolve/libs/unneeded
pkexec mv /opt/resolve/libs/libgio* /opt/resolve/libs/unneeded/
pkexec mv /opt/resolve/libs/libglib* /opt/resolve/libs/unneeded/
pkexec mv /opt/resolve/libs/libgmodule* /opt/resolve/libs/unneeded/

if [ $INSTALL_STATUS -eq 0 ]; then
    echo "Instalação concluída com sucesso."
else
    echo "[aviso] O instalador terminou, mas pode ter ocorrido algum erro."
fi

echo "Limpando o arquivo de download..."
rm "$LOCAL_FILE"

echo "Processo finalizado."
