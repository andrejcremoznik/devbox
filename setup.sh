#!/bin/bash

github_configs="https://raw.github.com/andrejcremoznik/devbox/raw/master/configs/"

echo "Installing software"
pacman -S openssh nginx nodejs npm

echo "Creating normal user 'dev'"
useradd -m -G http -s /bin/bash dev

echo "Set password for user 'dev'"
passwd dev

echo "Adding user 'dev' to sudoers"
echo -e "\ndev ALL=(ALL) ALL\n" >> /etc/sudoers

echo "Setting up WP-CLI, Composer, and NPM"
mkdir /home/dev/{.bin,.npm_global}
wget https://raw.github.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
mv wp-cli.phar /home/dev/.bin/wp
wget https://getcomposer.org/composer.phar
mv composer.phar /home/dev/.bin/composer
chmod u+x /home/dev/.bin/*
echo "prefix=~/.npm_global" > /home/dev/.npmrc

echo "Setting up .bashrc"
wget ${github_configs}.bashrc
mv .bashrc /home/dev/.bashrc

echo "Fixing file ownership"
chown dev:dev /home/dev -R

echo "Setting up Netctl"
# TODO

echo "Setting up SSHD"
wget ${github_configs}sshd_config
mv /etc/ssh/sshd_config /etc/ssh/sshd_config.old
mv sshd_config /etc/ssh/sshd_config
systemctl start sshd.service
systemctl enable sshd.service

echo "Setting up time sync"
echo -e "[Time]\nNTP=ntp1.arnes.si ntp2.arnes.si\nFallbackNTP=0.arch.pool.ntp.org 1.arch.pool.ntp.org\n" > /etc/systemd/timesyncd.conf
timedatectl set-ntp true
