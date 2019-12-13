#!/usr/bin/env bash

echo "==> Install NodeJS and NPM"
pacman -Sy nodejs npm

echo "==> Set up NodeJS"
mkdir -p /home/dev/node/bin
chown -R dev:dev /home/dev/node
echo "prefix=/home/dev/node
" > /home/dev/.npmrc

chown dev:dev /home/dev/.npmrc

echo "==> Done."
