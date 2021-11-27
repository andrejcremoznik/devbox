#!/usr/bin/env bash

pacman -S --noconfirm postgresql

echo "Set password for postgres user"
passwd postgres
su -c "initdb --locale en_US.UTF-8 -E UTF8 -D '/var/lib/postgres/data'" postgres
systemctl start postgresql.service
systemctl enable postgresql.service
su -c "createuser -d -r -s dev" postgres
su -c "createdb dev" dev

read -r -p "Install PHP-FPM extension? (y/n): " withPhp
[ "${withPhp}" != "y" ] && { echo "==> Done."; exit 0; }

pacman -S --noconfirm php-pgsql

echo "extension = pdo_pgsql.so
extension = pgsql.so" > /etc/php/conf.d/pgsql.ini

systemctl restart php-fpm.service

echo "==> Done."
