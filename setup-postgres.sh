#!/bin/bash

echo "==> Install PostgreSQL"
pacman -S postgresql php-pgsql

echo "==> Set up PostgreSQL"
echo "Set a password for postgres user"
passwd postgres
su -c "initdb --locale en_US.UTF-8 -E UTF8 -D '/var/lib/postgres/data'" postgres
systemctl start postgresql.service
systemctl enable postgresql.service
su -c "createuser -d -r -s dev" postgres
su -c "createdb dev" dev

echo "extension=pdo_pgsql.so
extension=pgsql.so" > /etc/php/conf.d/90-pgsql.ini
echo "Reboot or restart PHP-FPM to load the PostgreSQL extension"

echo "==> Done. You can install PhpPgAdmin to /srv/http/devbox.dev/phppgadmin if you need it."
