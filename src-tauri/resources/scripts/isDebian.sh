#!/bin/sh
# Script para verificar se a distribuição é um derivado de Debian.

# Define o nome do arquivo a ser verificado
OS_RELEASE_FILE="/etc/os-release"

# Verifica se o arquivo existe
if [ ! -f "$OS_RELEASE_FILE" ]; then
    echo "Erro: Arquivo $OS_RELEASE_FILE não encontrado."
    echo "Não é possível determinar a distribuição."
    exit 1
fi

# Lê o arquivo e extrai as variáveis ID e ID_LIKE
. /etc/os-release

# Verifica se a distribuição é Debian ou um derivado
# A verificação agora é feita de forma compatível com o shell POSIX (sh).
if [ "$ID" = "debian" ] || echo "$ID_LIKE" | tr '[:upper:]' '[:lower:]' | grep -q "debian"; then
    echo "Sucesso: A distribuição ($PRETTY_NAME) é um derivado de Debian."
    exit 0
else
    echo "Falha: A distribuição ($PRETTY_NAME) NÃO é um derivado de Debian."
    exit 1
fi