#!/usr/bin/env bash

echo "==> Install MariaDB"
pacman -Syu
pacman -S mariadb

echo "==> Set up MySQL"
sed -i "s|log-bin=mysql-bin|#log-bin=mysql-bin|g" /etc/mysql/my.cnf
sed -i "s|binlog_format=mixed|#binlog_format=mixed|g" /etc/mysql/my.cnf
mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
systemctl start mysqld.service
systemctl enable mysqld.service
mysql_secure_installation

read -e -p "Install PHP-FPM extension? (y/n): " withPhp
if [ "$withPhp" != "y" ]; then
  echo "==> Done."
  exit
fi

echo "extension=mysqli.so
extension=pdo_mysql.so
" > /etc/php/conf.d/90-mysql.ini

systemctl restart php-fpm.service

echo "==> Done. You can install PhpMyAdmin to /srv/http/devbox.dev/phpmyadmin if you need it."
