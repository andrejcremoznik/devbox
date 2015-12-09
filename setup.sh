#!/bin/bash

github_configs="https://github.com/andrejcremoznik/devbox/raw/master/configs/"

echo "Installing software"
pacman -S openssh nginx nodejs npm git tig mariadb postgresql php php-fpm php-gd php-intl php-mcrypt php-pear php-pgsql php-sqlite

echo "Creating normal user 'dev'"
useradd -m -G http -s /bin/bash dev

echo "Set password for user 'dev'"
passwd dev

echo "Adding user 'dev' to sudoers"
echo -e "\ndev ALL=(ALL) ALL\n" >> /etc/sudoers

echo "Setting up WP-CLI, Composer, and NPM"
mkdir /home/dev/{.bin,.npm_global}
wget -O /home/dev/.bin/wp https://raw.github.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
wget -O /home/dev/.bin/composer https://getcomposer.org/composer.phar
chmod u+x /home/dev/.bin/*
echo -e "prefix=~/.npm_global\n" > /home/dev/.npmrc

echo "Setting up .bashrc"
wget -O /home/dev/.bashrc ${github_configs}.bashrc

echo "Configuring Git"
wget -O /home/dev/.gitconfig ${github_configs}.gitconfig
wget -O /home/dev/.gitignore_global ${github_configs}.gitignore_global

echo "Fixing file ownership"
chown dev:dev /home/dev -R

echo "Setting up Netctl"
ip link show
read -e -p "NAT interface: " nInt
read -e -p "Host-only interface: " hInt
read -e -p "Devbox IP: " -i "10.10.0." hIP
echo -e "Description='DHCP net'\nInterface=$nInt\nConnection=ethernet\nIP=dhcp\n" > /etc/netctl/devbox-dhcp
echo -e "Description='Host net'\nInterface=$hInt\nConnection=ethernet\nIP=static\nAddress=('$hIP/24')\nDNS=('10.10.0.1')\n" > /etc/netctl/devbox-host
netctl enable devbox-dhcp
netctl enable devbox-host

echo "Setting up SSHD"
mv /etc/ssh/sshd_config /etc/ssh/sshd_config.old
wget -O /etc/ssh/sshd_config ${github_configs}sshd_config
systemctl enable sshd.service

echo "Setting up time sync"
echo -e "[Time]\nNTP=ntp1.arnes.si ntp2.arnes.si\nFallbackNTP=0.arch.pool.ntp.org 1.arch.pool.ntp.org\n" > /etc/systemd/timesyncd.conf
timedatectl set-ntp true

echo "Setting up MySQL"
sed -i "s|log-bin=mysql-bin|#log-bin=mysql-bin|g" /etc/mysql/my.cnf
sed -i "s|binlog_format=mixed|#binlog_format=mixed|g" /etc/mysql/my.cnf
mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
systemctl start mysqld.service
systemctl enable mysqld.service
mysql_secure_installation

# TODO: Postgres

echo "Setting up PHP"
wget -O /etc/php/conf.d/devbox.ini ${github_configs}php.ini
systemctl enable php-fpm.service

echo "Setting up Nginx"
mkdir -p /srv/http/devbox.dev/{etc,webdir}



chown dev:dev /srv/http -R
