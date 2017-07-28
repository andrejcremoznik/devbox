#!/bin/bash

github_configs="https://raw.githubusercontent.com/andrejcremoznik/devbox/master/configs/"

read -p "==> Install software"
pacman -S openssh wget nginx nodejs git mariadb postgresql php php-fpm php-gd php-intl php-mcrypt php-pgsql php-sqlite postfix dovecot rsync screen bash-completion

read -p "==> Create normal user 'dev' and set its password"
useradd -m -G http -s /bin/bash dev
passwd dev
echo -e "\ndev ALL=(ALL) ALL\n" >> /etc/sudoers

read -p "==> Set up WP-CLI, Composer, NPM, SSH config"
mkdir /home/dev/{bin,node,.ssh}
wget -O /home/dev/bin/wp https://raw.github.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
wget -O /home/dev/bin/composer https://getcomposer.org/composer.phar
chmod u+x /home/dev/bin/*
echo -e "prefix=~/node\n" > /home/dev/.npmrc
echo -e "host github\n  hostname github.com\n  user git" > /home/dev/.ssh/config

read -p "==> Set up .bashrc"
wget -O /home/dev/.bashrc ${github_configs}bashrc

read -p "==> Fix file ownership in /home/dev"
chown -R dev:dev /home/dev

read -p "==> Set up Netctl"
ip link show
read -e -p "NAT interface: " -i "enp0s3" nInt
read -e -p "Host-only interface: " -i "enp0s8" hInt
read -e -p "Devbox IP: " -i "10.10.0." hIP
echo -e "Description='DHCP net'\nInterface=$nInt\nConnection=ethernet\nIP=dhcp\n" > /etc/netctl/devbox-dhcp
echo -e "Description='Host net'\nInterface=$hInt\nConnection=ethernet\nIP=static\nAddress=('$hIP/24')\nDNS=('10.10.0.1')\n" > /etc/netctl/devbox-host
netctl enable devbox-dhcp
netctl enable devbox-host

read -p "==> Set up SSHD"
mv /etc/ssh/sshd_config /etc/ssh/sshd_config.old
wget -O /etc/ssh/sshd_config ${github_configs}sshd_config
systemctl enable sshd.service

read -p "==> Set up time sync"
echo -e "[Time]\nNTP=ntp1.arnes.si ntp2.arnes.si\nFallbackNTP=0.arch.pool.ntp.org 1.arch.pool.ntp.org\n" > /etc/systemd/timesyncd.conf
timedatectl set-ntp true

read -p "==> Configure Journal daemon"
mkdir -p /etc/systemd/journal.conf.d
echo -e "[Journal]\nSystemMaxUse=16M" > /etc/systemd/journal.conf.d/00-journal-size.conf
systemctl stop systemd-journald
rm -fr /var/log/journal/*
systemctl start systemd-journald

read -p "==> Set up MySQL"
sed -i "s|log-bin=mysql-bin|#log-bin=mysql-bin|g" /etc/mysql/my.cnf
sed -i "s|binlog_format=mixed|#binlog_format=mixed|g" /etc/mysql/my.cnf
mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
systemctl start mysqld.service
systemctl enable mysqld.service
mysql_secure_installation

read -p "==> Set up PostgreSQL"
echo "Set a password for postgres user"
passwd postgres
su -c "initdb --locale en_US.UTF-8 -E UTF8 -D '/var/lib/postgres/data'" postgres
systemctl start postgresql.service
systemctl enable postgresql.service
su -c "createuser -d -r -s dev" postgres
su -c "createdb dev" dev

read -p "==> Set up PHP"
wget -O /etc/php/conf.d/devbox.ini ${github_configs}php.ini
systemctl enable php-fpm.service

read -p "==> Set up Postfix and Dovecot"
echo -e "\ninet_interfaces = loopback-only\nmynetworks_style = host\nhome_mailbox = Maildir/\ncanonical_maps = regexp:/etc/postfix/canonical-redirect\n" >> /etc/postfix/main.cf
echo -e "/^.*$/ dev\n" > /etc/postfix/canonical-redirect
if [ -f /etc/dovecot/dovecot.conf ]; then
  mv /etc/dovecot/dovecot.conf /etc/dovecot/dovecot.conf.old
fi
wget -O /etc/dovecot/dovecot.conf ${github_configs}dovecot.conf
systemctl enable postfix.service
systemctl enable dovecot.service
newaliases

read -p "==> Set up Nginx"
mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.old
mv /etc/nginx/mime.types /etc/nginx/mime.types.old
wget -O /etc/nginx/nginx.conf ${github_configs}nginx.main.conf
wget -O /etc/nginx/mime.types ${github_configs}mime.types
read -e -p "Devbox domain: " -i "devbox.dev" domain
mkdir -p /srv/http/${domain}/{etc,webdir}
wget -O /srv/http/${domain}/etc/nginx.conf ${github_configs}nginx.vhost.conf
sed -i "s/devbox.dev/${domain}/g" /srv/http/${domain}/etc/nginx.conf
wget -O /srv/http/${domain}/webdir/index.html ${github_configs}index.html
echo -e "<?php phpinfo();\n" > /srv/http/${domain}/webdir/phpinfo.php
systemctl enable nginx.service

read -p "==> Set up PhpMyAdmin"
mkdir /srv/http/${domain}/webdir/{phpmyadmin,phppgadmin,roundcube}
wget -O phpmyadmin.tar.gz https://github.com/phpmyadmin/phpmyadmin/tarball/master
tar -zxf phpmyadmin.tar.gz -C /srv/http/${domain}/webdir/phpmyadmin --strip-components=1

read -p "==> Set up PhpPgAdmin"
wget -O phppgadmin.tar.gz https://github.com/phppgadmin/phppgadmin/tarball/master
tar -zxf phppgadmin.tar.gz -C /srv/http/${domain}/webdir/phppgadmin --strip-components=1
cp /srv/http/${domain}/webdir/phppgadmin/conf/config.inc.php-dist /srv/http/${domain}/webdir/phppgadmin/conf/config.inc.php

read -p "==> Set up Roundcube"
wget -O roundcube.tar.gz https://github.com/roundcube/roundcubemail/tarball/master
tar -zxf roundcube.tar.gz -C /srv/http/${domain}/webdir/roundcube --strip-components=1
mysql -u root -pdev -e "CREATE DATABASE roundcube;"
wget -O /srv/http/${domain}/webdir/roundcube/config/config.inc.php ${github_configs}roundcube.php
mysql -u root -pdev roundcube < /srv/http/${domain}/webdir/roundcube/SQL/mysql.initial.sql
chmod a+rwx /srv/http/${domain}/webdir/roundcube/logs /srv/http/${domain}/webdir/roundcube/temp
wget -O /srv/http/${domain}/webdir/roundcube/config/mime.types http://svn.apache.org/repos/asf/httpd/httpd/trunk/docs/conf/mime.types

read -p "==> Fix file ownership in /srv/http"
chown -R dev:dev /srv/http

read -p "==> Cleanup pacman cache"
pacman -Scc
pacman-optimize

echo "Done. Please reboot the VM and add '$hIP $domain' to /etc/hosts on your host machine."
