#!/bin/sh

# --- Determina o diretório home e o nome de usuário corretos ---
# Quando executado com pkexec, o HOME é /root, mas PKEXEC_UID tem o ID do usuário original.
if [ -n "$PKEXEC_UID" ]; then
  USER_HOME=$(getent passwd "$PKEXEC_UID" | cut -d: -f6)
  USER_NAME=$(getent passwd "$PKEXEC_UID" | cut -d: -f1)
else
  # Fallback para caso seja executado sem pkexec (para testes)
  USER_HOME=$HOME
  USER_NAME=$USER
fi

# Aborta se não conseguir encontrar o diretório home
if [ -z "$USER_HOME" ] || [ -z "$USER_NAME" ]; then
  echo "[erro] Não foi possível determinar o usuário ou o diretório 'home'."
  exit 1
fi

# --- Configura os caminhos ---
DOWNLOAD_DIR="$USER_HOME/Downloads"
TOOLBOX_URL="https://data.services.jetbrains.com/products/download?platform=linux&code=TBA"
DOWNLOAD_FILE="jetbrains-toolbox.tar.gz"

echo "Diretório de destino: $DOWNLOAD_DIR"

# Garante que o diretório de Downloads exista, criando-o como o usuário correto
sudo -u "$USER_NAME" mkdir -p "$DOWNLOAD_DIR"

# Muda para o diretório de Downloads
cd "$DOWNLOAD_DIR" || { echo "[erro] Não foi possível acessar $DOWNLOAD_DIR"; exit 1; }

echo "Iniciando o download do JetBrains Toolbox..."
# Usamos -q (quiet) e --show-progress para um output mais limpo
wget -q --show-progress -c "$TOOLBOX_URL" -O "$DOWNLOAD_FILE"

if [ $? -ne 0 ]; then
    echo "[erro] O download falhou."
    exit 1
fi

echo "Arquivo baixado com sucesso. Extraindo..."
# Extrai o conteúdo como o usuário correto para evitar problemas de permissão
sudo -u "$USER_NAME" tar -xzf "$DOWNLOAD_FILE"
if [ $? -ne 0 ]; then
    echo "[erro] A extração do arquivo falhou."
    rm "$DOWNLOAD_FILE"
    exit 1
fi

echo "Arquivos extraídos. Procurando o executável..."
# Encontra o diretório que foi extraído (ex: ./jetbrains-toolbox-2.8.1)
EXTRACTED_DIR=$(find . -maxdepth 1 -type d -name "jetbrains-toolbox-*")

if [ -z "$EXTRACTED_DIR" ]; then
    echo "[erro] Não foi possível encontrar o diretório extraído."
    rm "$DOWNLOAD_FILE"
    exit 1
fi

echo "Diretório extraído encontrado: $EXTRACTED_DIR"

# --- LÓGICA CORRIGIDA ---
# Procura pelo arquivo 'jetbrains-toolbox' dentro do diretório extraído
TOOLBOX_EXEC=$(find "$EXTRACTED_DIR" -type f -name "jetbrains-toolbox")

if [ -f "$TOOLBOX_EXEC" ]; then
    echo "Executável encontrado em: $TOOLBOX_EXEC"
    echo "Iniciando o JetBrains Toolbox..."
    # Executa o aplicativo como o usuário original e em segundo plano
    sudo -u "$USER_NAME" nohup "$TOOLBOX_EXEC" > /dev/null 2>&1 &
else
    echo "[erro] O executável 'jetbrains-toolbox' não foi encontrado dentro de '$EXTRACTED_DIR'."
    # Para depuração, lista o conteúdo da pasta se o executável não for encontrado
    echo "Conteúdo de '$EXTRACTED_DIR':"
    ls -lR "$EXTRACTED_DIR"
    exit 1
fi

echo "Limpando o arquivo de instalação..."
rm "$DOWNLOAD_FILE"

echo "O JetBrains Toolbox foi iniciado com sucesso."
echo "Os arquivos foram extraídos em: $DOWNLOAD_DIR"
