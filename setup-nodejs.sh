#!/usr/bin/env bash

pacman -S --noconfirm nodejs npm

mkdir -p /home/dev/node/bin
chown -R dev:dev /home/dev/node
echo "prefix=/home/dev/node
" > /home/dev/.npmrc

chown dev:dev /home/dev/.npmrc

sed -i "s|\${HOME}/bin|\${HOME}/bin:\${HOME}/node/bin|" /home/dev/.bash_profile

echo "==> Done."
