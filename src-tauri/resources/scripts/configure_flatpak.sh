#!/bin/sh
# Script para verificar se o ambiente de desktop é GNOME ou KDE Plasma.

# O método mais padrão e confiável é inspecionar a variável XDG_CURRENT_DESKTOP.
# Esta variável pode conter uma lista de valores separados por dois pontos (ex: "GNOME:GNOME-Classic"),
# então verificamos se a string contém "gnome" ou "kde"/"plasma".

if [ -n "$XDG_CURRENT_DESKTOP" ]; then
    # Converte a variável para minúsculas para garantir a correspondência
    desktop_env=$(echo "$XDG_CURRENT_DESKTOP" | tr '[:upper:]' '[:lower:]')

    case "$desktop_env" in
        *gnome*)
            echo "Ambiente de desktop detectado: GNOME"
            apt install flatpak
            apt install gnome-software-plugin-flatpak
            flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
            echo 'É preciso reiniciar para aplicar as alterações.'
            exit 0
            ;;
        *kde*|*plasma*)
            # O ambiente KDE pode se identificar como 'kde' ou, mais recentemente, 'plasma'
            echo "Ambiente de desktop detectado: KDE Plasma"
            apt install kde-config-flatpak
            echo 'É preciso reiniciar para aplicar as alterações.'
            exit 0
            ;;
    esac
fi

# Se nenhum dos métodos acima funcionou
echo "Não foi possível determinar se o ambiente é GNOME ou KDE."
exit 1

