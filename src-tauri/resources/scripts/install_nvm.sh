#!/bin/sh

wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
nvm install --lts
echo 'NVM instalado com sucesso.'