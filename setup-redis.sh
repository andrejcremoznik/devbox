#!/usr/bin/env bash

pacman -S --noconfirm redis

mkdir -p /etc/tmpfiles.d

echo "w /sys/kernel/mm/transparent_hugepage/enabled - - - - never
w /sys/kernel/mm/transparent_hugepage/defrag - - - - never" > /etc/tmpfiles.d/redis.conf

systemctl start redis.service
systemctl enable redis.service

read -r -p "Install PHP-FPM extension? (y/n): " withPhp
[ "${withPhp}" != "y" ] && { echo "==> Done."; exit 0; }

pacman -S --noconfirm php-redis php-igbinary

echo "extension=redis.so" > /etc/php/conf.d/redis.ini
echo "extension=igbinary.so" > /etc/php/conf.d/igbinary.ini

systemctl restart php-fpm.service

echo "==> Done."
