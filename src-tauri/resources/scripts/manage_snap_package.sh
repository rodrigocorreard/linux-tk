#!/bin/bash


if ! command -v snap >/dev/null 2>&1; then
  echo "Erro: O suporte ao Snap não está instalado ou não está no PATH." >&2
  echo "Por favor, habilite os snaps e tente novamente." >&2
  exit 1
fi

# Validação básica dos argumentos
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Erro: Ação (install/remove) e nome do pacote são necessários."
  exit 1
fi

ACTION=$1
PACKAGE_NAME=$2

echo "Ação: $ACTION"
echo "Pacote: $PACKAGE_NAME"
echo "Gerenciador: Snap"
echo "Uma senha de administrador pode ser solicitada..."
echo "---------------------------------------------------"

# Executa o comando apropriado com pkexec
case "$ACTION" in
  install)
    pkexec snap install "$PACKAGE_NAME"
    ;;
  remove)
    pkexec snap remove "$PACKAGE_NAME"
    ;;
  *)
    echo "Erro: Ação desconhecida '$ACTION'. Use 'install' ou 'remove'."
    exit 1
    ;;
esac

# Verifica o código de saída do comando anterior
if [ $? -eq 0 ]; then
  echo "---------------------------------------------------"
  echo "Sucesso: Ação '$ACTION' para o pacote '$PACKAGE_NAME' foi concluída."
  exit 0
else
  echo "---------------------------------------------------"
  echo "Erro: Falha ao executar a ação '$ACTION' para o pacote '$PACKAGE_NAME'."
  exit 1
fi
