#!/usr/bin/env bash

pacman -S --noconfirm mariadb

mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
systemctl start mysqld.service
systemctl enable mysqld.service
mysql_secure_installation

read -r -p "Install PHP-FPM extension? (y/n): " withPhp
[ "${withPhp}" != "y" ] && { echo "==> Done."; exit 0; }

echo "extension=mysqli.so
extension=pdo_mysql.so" > /etc/php/conf.d/mysql.ini

systemctl restart php-fpm.service

echo "==> Done."
