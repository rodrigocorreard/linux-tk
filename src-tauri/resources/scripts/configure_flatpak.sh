#!/bin/sh

if pgrep -x "gnome-shell" >/dev/null; then
  echo "Ambiente GNOME detectado."
      apt install -y flatpak
      apt install -y gnome-software-plugin-flatpak
      flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
      echo 'É preciso reiniciar para aplicar as alterações.'
      exit 0

elif pgrep -x "plasmashell" >/dev/null; then
  echo "Ambiente KDE Plasma detectado."
      apt install -y kde-config-flatpak
      flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
      echo 'É preciso reiniciar para aplicar as alterações.'
      exit 0

else
  echo "Não foi possível detectar GNOME ou KDE pelos processos em execução." >&2
  exit 1
fi

## Pega a variável e converte para letras minúsculas para facilitar a verificação
#if [ -n "$XDG_CURRENT_DESKTOP" ]; then
#  CURRENT_DESKTOP=$(echo "$XDG_CURRENT_DESKTOP" | tr '[:upper:]' '[:lower:]')
#else
#  echo "A variável XDG_CURRENT_DESKTOP não está definida. Não é possível detectar o ambiente." >&2
#  exit 1
#fi
#
## Usa 'case' com asteriscos para procurar por substrings
#case "$CURRENT_DESKTOP" in
#  *gnome*)
#    echo "Ambiente GNOME detectado."
#    apt install -y flatpak
#    apt install -y gnome-software-plugin-flatpak
#    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
#    echo 'É preciso reiniciar para aplicar as alterações.'
#    exit 0
#    ;;
#  *kde*|*plasma*)
#    echo "Ambiente KDE Plasma detectado."
#    apt install -y kde-config-flatpak
#    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
#    echo 'É preciso reiniciar para aplicar as alterações.'
#    exit 0
#    ;;
#  *)
#    echo "Não foi possível identificar o ambiente como GNOME ou KDE." >&2
#    echo "Valor encontrado: '$XDG_CURRENT_DESKTOP'"
#    exit 1
#    ;;
#esac

