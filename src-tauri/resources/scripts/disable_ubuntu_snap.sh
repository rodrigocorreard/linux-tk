#!/bin/bash

# Este script verifica se o snapd está em operação.

systemctl is-active --quiet snapd >/dev/null 2>&1
status=$?

# Ação baseada no código de retorno
if [ $status -eq 0 ]; then
  echo "O serviço 'snapd' está em operação (ativo)."
  systemctl stop snapd
  systemctl mask snapd
  echo "O serviço 'snapd' foi desabilitado."
else
  echo "O serviço 'snapd' NÃO está em operação (inativo)."
fi

exit 0

