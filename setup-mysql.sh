#!/bin/bash

echo "==> Install MariaDB"
pacman -S mariadb

echo "==> Set up MySQL"
sed -i "s|log-bin=mysql-bin|#log-bin=mysql-bin|g" /etc/mysql/my.cnf
sed -i "s|binlog_format=mixed|#binlog_format=mixed|g" /etc/mysql/my.cnf
mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
systemctl start mysqld.service
systemctl enable mysqld.service
mysql_secure_installation

echo "extension=mysqli.so
extension=pdo_mysql.so" > /etc/php/conf.d/90-mysql.ini
echo "Reboot or restart PHP-FPM to load the MySQL extension"

pacman -Scc

read -e -p "==> Install PhpMyAdmin? (y/n): " cont
if [ "$cont" != "y" ]; then
  exit
fi

DIR=/srv/http/devbox.dev/phpmyadmin

mkdir -p ${DIR}

curl -L https://github.com/phpmyadmin/phpmyadmin/tarball/master | tar zxf - --strip-components=1 -C ${DIR}

echo "<li><a href=\"/phpmyadmin/\">PhpMyAdmin</a> (root / dev)</li>" >> /srv/http/devbox.dev/index.html

echo "==> Fix file ownership"
chown -R dev:dev ${DIR}

echo "==> Done"
