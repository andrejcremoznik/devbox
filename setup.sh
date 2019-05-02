#!/usr/bin/env bash

echo "==> Install software"
pacman -Syu
pacman -S openssh nginx git bash-completion unzip sudo

echo "==> Create normal user 'dev' and set password"
useradd -m -G http -s /bin/bash dev
passwd dev
echo "dev ALL=(ALL) ALL
" >> /etc/sudoers

echo "==> Set up SSH config"
mkdir -p /home/dev/{bin,node/bin,.ssh}

echo "host github
  hostname github.com
  user git
" > /home/dev/.ssh/config

echo "==> Set up Bash"
echo "export EDITOR=nano
export VISUAL=nano
export PATH=\$PATH:\$HOME/bin:\$HOME/node/bin
[[ -f ~/.bashrc ]] && . ~/.bashrc
" > /home/dev/.bash_profile

echo "[[ \$- != *i* ]] && return
export HISTSIZE=5000
export HISTFILESIZE=10000
export HISTCONTROL=ignoreboth,ignoredups
export PROMPT_COMMAND='history -a'
shopt -s histappend
shopt -s globstar
alias ls='ls -h --group-directories-first --time-style=+\"%d.%m.%Y %H:%M\" --color=auto -F'
alias ll='ls -lh --group-directories-first --time-style=+\"%d.%m.%Y %H:%M\" --color=auto -F'
alias la='ls -la --group-directories-first --time-style=+\"%d.%m.%Y %H:%M\" --color=auto -F'
alias grep='grep --color=auto -d skip'
alias cp='cp -i'
alias mv='mv -i'
alias ..='cd ..'
alias ram='ps axch -o cmd:15,%mem --sort=-%mem | head'
PS1='[\\u@\\h \\w]\\\$ '
" > /home/dev/.bashrc

echo "==> Set up .gitconfig"
read -e -p "Your name: " gitName
read -e -p "Your e-mail: " gitEmail
echo "[user]
  name = $gitName
  email = $gitEmail
[core]
  autocrlf = input
[color]
  ui = auto
  diff = auto
  status = auto
  branch = auto
[alias]
  lg = log --graph -n 20 --abbrev-commit --date=relative --pretty=format:'%h -%C(yellow)%d%Creset %s %Cgreen(%cr)%Creset %Cblue<%an>%Creset'
  st = status
  gca = gc --aggressive
  prb = pull --rebase
  rprune = remote update --prune
[push]
  default = simple
" > /home/dev/.gitconfig

echo "==> Fix file ownership in /home/dev"
chown -R dev:dev /home/dev

echo "==> Set up Netctl"
ip link show
read -e -p "NAT interface: " -i "enp0s3" nInt
read -e -p "Host-only interface: " -i "enp0s8" hInt
read -e -p "Devbox IP: " -i "10.10.0." hIP
echo "Description='DHCP net'
Interface=$nInt
Connection=ethernet
IP=dhcp
" > /etc/netctl/devbox-dhcp
echo "Description='Host net'
Interface=$hInt
Connection=ethernet
IP=static
Address=('$hIP/24')
DNS=('10.10.0.1')
" > /etc/netctl/devbox-host
netctl enable devbox-dhcp
netctl enable devbox-host

echo "==> Set up SSHD"
echo "Protocol 2
PasswordAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
AllowAgentForwarding yes
PrintMotd no
Subsystem sftp /usr/lib/ssh/sftp-server
" > /etc/ssh/sshd_config
systemctl enable sshd.service

echo "==> Set up time sync"
echo "[Time]
NTP=ntp1.arnes.si ntp2.arnes.si
FallbackNTP=0.arch.pool.ntp.org 1.arch.pool.ntp.org
" > /etc/systemd/timesyncd.conf
timedatectl set-ntp true

echo "==> Configure Journal daemon"
mkdir -p /etc/systemd/journal.conf.d
echo "[Journal]
SystemMaxUse=8M
" > /etc/systemd/journal.conf.d/00-journal-size.conf
systemctl stop systemd-journald
rm -fr /var/log/journal/*
systemctl start systemd-journald

echo "==> Set up Nginx"
mkdir -p /var/log/nginx
touch /var/log/nginx/access.log
touch /var/log/nginx/error.log
mkdir -p /etc/nginx/{sites-available,sites-enabled,conf.d}

echo "user http http;
worker_processes auto;
worker_rlimit_nofile 8192;
events { worker_connections 8000; }
http {
  include              mime.types;
  default_type         application/octet-stream;
  charset              utf-8;
  charset_types
    text/css text/plain text/vnd.wap.wml
    application/javascript application/json application/rss+xml application/xml;
  index                index.html index.php;
  log_format  main     '\$remote_addr - \$remote_user [\$time_local] \"\$request\" '
                       '\$status \$body_bytes_sent \"\$http_referer\" '
                       '\"\$http_user_agent\" \"\$http_x_forwarded_for\"';
  access_log           /var/log/nginx/access.log main;
  error_log            /var/log/nginx/error.log error;
  client_max_body_size 20m;
  keepalive_timeout    20s;
  sendfile             on;
  tcp_nopush           on;
  gzip                 off;
  server {
    listen 80 default_server;
    return 444;
  }
  include sites-enabled/*.conf;
}
" > /etc/nginx/nginx.conf

mkdir -p /srv/http/devbox.dev
echo "<!DOCTYPE html>
<h1>Devbox Tools</h1>
<ul>
" > /srv/http/devbox.dev/index.html
chown -R dev:dev /srv/http

echo "server {
  listen      [::]:80;
  listen      80;
  server_name devbox.dev;
  root        /srv/http/devbox.dev;
  access_log  off;
  location ~ \\.php\$ {
    try_files \$uri =404;
    fastcgi_index index.php;
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    fastcgi_pass unix:/run/php-fpm/php-fpm.sock;
  }
}
" > /etc/nginx/sites-available/devbox.dev.conf

ln -s /etc/nginx/sites-available/devbox.dev.conf /etc/nginx/sites-enabled/devbox.dev.conf

systemctl enable nginx.service

echo "==> Done."
