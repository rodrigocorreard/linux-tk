#!/bin/bash

# Valida os argumentos: Ação (install/remove) e Nome do Pacote
if [ "$#" -ne 2 ]; then
    echo "Uso: $0 <install|remove> <nome-do-pacote>"
    exit 1
fi

ACTION=$1
PACKAGE_NAME=$2
COMMAND=""

# Define o comando apt com base na ação
if [ "$ACTION" = "install" ]; then
    COMMAND="apt-get install -y"
    echo "Iniciando a instalação de: $PACKAGE_NAME"
elif [ "$ACTION" = "remove" ]; then
    # Usamos 'purge' para remover também os arquivos de configuração
    COMMAND="apt-get purge -y"
    echo "Iniciando a remoção de: $PACKAGE_NAME"

else
    echo "Erro: Ação inválida '$ACTION'. Use 'install' ou 'remove'."
    exit 1
fi

echo "Uma senha de administrador pode ser solicitada..."
echo "---------------------------------------------------"

# Usa pkexec para executar o comando apt com privilégios de administrador
pkexec $COMMAND "$PACKAGE_NAME"

# Verifica o código de saída do comando
if [ $? -eq 0 ]; then
    echo "---------------------------------------------------"
    echo "Sucesso: Ação '$ACTION' para o pacote '$PACKAGE_NAME' concluída."
    exit 0
else
    echo "---------------------------------------------------"
    echo "Erro: Falha ao executar a ação '$ACTION' para o pacote '$PACKAGE_NAME'."
    exit 1
fi
