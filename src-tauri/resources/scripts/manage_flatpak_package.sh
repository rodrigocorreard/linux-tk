#!/bin/bash

# Este script gerencia pacotes Flatpak (instalação/remoção) usando pkexec
# para elevação de privilégios.

# Verifica se os argumentos necessários foram fornecidos
if [ "$#" -ne 2 ]; then
    echo "Uso: $0 <install|remove> <flatpak_id>"
    exit 1
fi

ACTION="$1"
PACKAGE_ID="$2"

# Função para instalar um pacote
install_package() {
    echo "Tentando instalar o Flatpak: $PACKAGE_ID"
    pkexec flatpak install --system --noninteractive --assumeyes "$PACKAGE_ID"
}

# Função para remover um pacote
remove_package() {
    echo "Tentando remover o Flatpak: $PACKAGE_ID"
    pkexec flatpak uninstall --system --noninteractive --assumeyes "$PACKAGE_ID"
}

# Executa a ação apropriada
case "$ACTION" in
    install)
        install_package
        ;;
    remove)
        remove_package
        ;;
    *)
        echo "Ação inválida: $ACTION. Use 'install' ou 'remove'."
        exit 1
        ;;
esac

# Verifica o código de saída da operação
if [ $? -eq 0 ]; then
    echo "Operação '$ACTION' para o pacote '$PACKAGE_ID' concluída com sucesso."
    exit 0
else
    echo "Erro durante a operação '$ACTION' para o pacote '$PACKAGE_ID'."
    exit 1
fi
