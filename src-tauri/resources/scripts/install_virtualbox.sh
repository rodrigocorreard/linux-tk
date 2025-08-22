#!/bin/bash

# Verifica se o script está sendo executado como root
if [ "$(id -u)" -ne 0 ]; then
  echo "Este script precisa ser executado como root." >&2
  exit 1
fi

# Verifica se a CPU é AMD
if grep -q -i "vendor_id.*AuthenticAMD" /proc/cpuinfo; then
  echo "Plataforma AMD detectada."

  # Verifica se o módulo kvm_amd está carregado
  if lsmod | grep -q "kvm_amd"; then
    echo "O módulo KVM para AMD (kvm_amd) está carregado. Removendo..."
    # Remove o módulo para evitar conflitos com o VirtualBox
    modprobe -r kvm_amd
    if [ $? -eq 0 ]; then
      echo "Módulo kvm_amd removido com sucesso."
    else
      echo "Atenção: Falha ao remover o módulo kvm_amd. A instalação pode prosseguir, mas o VirtualBox pode não funcionar corretamente." >&2
    fi
  else
    echo "O módulo kvm_amd não está carregado."
  fi

  # Adiciona o módulo à blacklist para impedir que seja carregado no boot
  BLACKLIST_FILE="/etc/modprobe.d/blacklist-kvm_amd.conf"
  if [ ! -f "$BLACKLIST_FILE" ] || ! grep -q -w "blacklist kvm_amd" "$BLACKLIST_FILE"; then
    echo "Adicionando o módulo kvm_amd à blacklist..."
    echo "# Desativado para evitar conflitos com o VirtualBox" >> "$BLACKLIST_FILE"
    echo "blacklist kvm_amd" >> "$BLACKLIST_FILE"
    echo "Módulo kvm_amd adicionado à blacklist em $BLACKLIST_FILE."
  else
    echo "O módulo kvm_amd já se encontra na blacklist."
  fi
fi

# Atualiza a lista de pacotes
echo "Atualizando a lista de pacotes (apt update)..."
apt-get update

# Instala o VirtualBox e os adicionais de convidado
echo "Instalando o VirtualBox e os adicionais de convidado..."
apt-get install -y virtualbox virtualbox-guest-additions-iso

if [ $? -eq 0 ]; then
  echo "VirtualBox instalado com sucesso!"
else
  echo "Ocorreu um erro durante a instalação do VirtualBox." >&2
  exit 1
fi

exit 0
