#!/usr/bin/env bash

echo "==> Install NodeJS and NPM"
pacman -Syu
pacman -S nodejs npm

echo "==> Set up NodeJS"

echo "prefix=${HOME}/node
" > /home/dev/.npmrc

chown dev:dev /home/dev/.npmrc

echo "==> Done."
