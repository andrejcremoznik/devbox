#!/bin/bash

read "==> Install PostgreSQL"
pacman -S postgresql php-pgsql

read "==> Set up PostgreSQL"
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

pacman -Scc

read -e -p "==> Install PhpPgAdmin? (y/n): " cont
if [ "$cont" != "y" ]; then
  exit
fi

DIR=/srv/http/devbox.dev/phppgadmin

mkdir -p ${DIR}

curl -L https://github.com/phppgadmin/phppgadmin/tarball/master | tar zxf - --strip-components=1 -C ${DIR}
cp ${DIR}/conf/config.inc.php-dist ${DIR}/conf/config.inc.php

echo "<li><a href=\"/phppgadmin/\">PhpPgAdmin</a> (dev / dev)</li>" >> /srv/http/devbox.dev/index.html

read "==> Fix file ownership"
chown -R dev:dev ${DIR}

read "==> Done"
