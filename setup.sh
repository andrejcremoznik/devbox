#!/usr/bin/env bash

# Set timezone
read -e -i "UTC" -r -p "Timezone (e.g. UTC or Europe/Amsterdam): " tz

[ -f "/usr/share/zoneinfo/${tz}" ] || { echo "Bad timezone"; exit 1; }

ln -sf "/usr/share/zoneinfo/${tz}" /etc/localtime


# Configure locale
echo "en_US.UTF-8 UTF-8
" > /etc/locale.gen

locale-gen

echo "LANG=en_US.UTF-8
" > /etc/locale.conf


# Configure hostname and hosts
read -e -i "devbox" -r -p "Hostname for this devbox: " hName

echo "${hName}
" > /etc/hostname

echo "127.0.0.1 localhost
::1 localhost
127.0.1.1 ${hName}.localdomain ${hName}
127.0.1.1 ${hName}.test
" > /etc/hosts


# Configure networks
mkdir -p /etc/systemd/network

nat_adapter=$(ip link show | grep "enp" | cut -d "<" -f 1 | tr -d ":" | cut -d " " -f 2 | head -n 1)
host_adapter=$(ip link show | grep "enp" | cut -d "<" -f 1 | tr -d ":" | cut -d " " -f 2 | tail -n 1)

echo "[Match]
Name=${nat_adapter}
[Network]
DHCP=ipv4
" > /etc/systemd/network/dhcp.network

read -e -i "10.10.0.2" -r -p "IP for this devbox: " vmIP # the IP depends on VM adapter configuration

echo "[Match]
Name=${host_adapter}
[Network]
Address=${vmIP}/24
" > /etc/systemd/network/host.network

systemctl enable systemd-networkd.service
systemctl enable systemd-resolved.service

# Set up a service to run a script at startup
echo "[Unit]
Description=Run a custom script at startup
After=default.target

[Service]
ExecStart=/opt/scripts/run-on-boot.sh

[Install]
WantedBy=default.target
" > /etc/systemd/system/run-on-boot.service

systemctl enable run-on-boot.service

mkdir -p /opt/scripts/run-on-boot-once

echo "#!/bin/sh

for file in /opt/scripts/run-on-boot-once/*; do
  [ ! -f \"\$file\" ] && continue
  \"\$file\"
  rm \"\$file\"
done
"> /opt/scripts/run-on-boot.sh

chmod +x /opt/scripts/run-on-boot.sh

# The systemd-resolved stub resolver needs to be set up after reboot
echo "#!/bin/sh
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
" > /opt/scripts/run-on-boot-once/01-stub-resolv.sh
chmod +x /opt/scripts/run-on-boot-once/01-stub-resolv.sh


# Time synchronization
read -e -i "0.europe.pool.ntp.org 1.europe.pool.ntp.org" -r -p "List primary NTP servers: " ntp
echo "[Time]
NTP=${ntp}
FallbackNTP=0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org
" > /etc/systemd/timesyncd.conf

# Enable NTP sync after reboot
echo "#!/bin/sh
timedatectl set-ntp true
" > /opt/scripts/run-on-boot-once/02-enable-ntp.sh
chmod +x /opt/scripts/run-on-boot-once/02-enable-ntp.sh


# Initramfs
mkinitcpio -P

# Configure bootloader
disk=$(lsblk -nrd -o NAME -I 8)
grub-install --target=i386-pc "/dev/${disk}"

echo "GRUB_DEFAULT=0
GRUB_TIMEOUT=1
GRUB_DISTRIBUTOR=\"Arch\"
GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet nowatchdog\"
GRUB_CMDLINE_LINUX=\"\"
GRUB_PRELOAD_MODULES=\"part_msdos\"
GRUB_TIMEOUT_STYLE=hidden
GRUB_TERMINAL_INPUT=console
GRUB_TERMINAL_OUTPUT=console
GRUB_GFXMODE=auto
GRUB_GFXPAYLOAD_LINUX=keep
GRUB_DISABLE_RECOVERY=true
" > /etc/default/grub

grub-mkconfig -o /boot/grub/grub.cfg


# FS optimization
sed -i "s/relatime/noatime/g" /etc/fstab


# Set smaller journal size
mkdir -p /etc/systemd/journal.conf.d
echo "[Journal]
SystemMaxUse=8M
" > /etc/systemd/journal.conf.d/journal-size.conf
systemctl stop systemd-journald
rm -fr /var/log/journal/*
systemctl start systemd-journald


# Install software
pacman -Sy --noconfirm openssh nginx git bash-completion fzf unzip
pacman -Scc --noconfirm


# Users
echo "Password for the root user"
passwd

useradd -m -G http -s /bin/bash dev

echo "Password for the dev user"
passwd dev

echo "dev ALL=(ALL) ALL
" >> /etc/sudoers

# Dev user configuration
mkdir -p /home/dev/{.ssh,bin}

echo "host github
  hostname github.com
  user git
" > /home/dev/.ssh/config

touch /home/dev/.ssh/known_hosts

echo "export EDITOR=nano
export VISUAL=nano

[ -d ~/bin ] && { PATH=\"\${PATH}:\${HOME}/bin\"; }
[ -d ~/node/bin ] && { PATH=\"\${PATH}:\${HOME}/node/bin\"; }

export PATH

[ -f ~/.bashrc ] && . ~/.bashrc
" > /home/dev/.bash_profile

echo "[[ \$- != *i* ]] && return

export HISTSIZE=5000
export HISTFILESIZE=10000
export HISTCONTROL=ignoreboth,ignoredups
export PROMPT_COMMAND='history -a'
shopt -s no_empty_cmd_completion
shopt -s histappend
shopt -s globstar

# Aliases
alias ls='ls -h --group-directories-first --time-style=+\"%d.%m.%Y %H:%M\" --color=auto -F'
alias ll='ls -lh --group-directories-first --time-style=+\"%d.%m.%Y %H:%M\" --color=auto -F'
alias la='ls -la --group-directories-first --time-style=+\"%d.%m.%Y %H:%M\" --color=auto -F'
alias grep='grep --color=auto -d skip'
alias cp='cp -i'
alias mv='mv -i'
alias ram='ps axch -o cmd:15,%mem --sort=-%mem | head'
alias reboot='sudo systemctl reboot'
alias shutdown='sudo systemctl poweroff'

# Fuzzy finder
source /usr/share/fzf/key-bindings.bash
source /usr/share/fzf/completion.bash
complete -o bashdefault -o default -F _fzf_path_completion nano

# Default prompt (w instead of W if you want full path)
PS1='[\\u@\\h \\W]\\\$ '
" > /home/dev/.bashrc

echo "Setting up .gitconfig"
read -r -p "Your name: " gitName
read -r -p "Your e-mail: " gitEmail
echo "[user]
  name = ${gitName}
  email = ${gitEmail}
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

chown -R dev:dev /home/dev


# SSHD configuration
echo "Protocol 2
PasswordAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
AllowAgentForwarding yes
PrintMotd no
Subsystem sftp /usr/lib/ssh/sftp-server
" > /etc/ssh/sshd_config
systemctl enable sshd.service


# Set up Nginx
mkdir -p /var/log/nginx
touch /var/log/nginx/access.log
touch /var/log/nginx/error.log
mkdir -p /etc/nginx/{sites,conf.d}

echo "user http http;
worker_processes auto;
worker_rlimit_nofile 8192;
events { worker_connections 8000; }
http {
  include              mime.types;
  default_type         application/octet-stream;
  charset              utf-8;
  charset_types        text/css text/plain text/vnd.wap.wml text/javascript text/markdown text/calendar text/x-component text/vcard text/cache-manifest text/vtt application/json application/manifest+json;
  index                index.html index.php;
  log_format  main     '\$remote_addr - \$remote_user [\$time_local] \"\$request\" \$status \$body_bytes_sent \"\$http_referer\" \"\$http_user_agent\" \"\$http_x_forwarded_for\"';
  access_log           /var/log/nginx/access.log main;
  error_log            /var/log/nginx/error.log error;
  client_max_body_size 20m;
  keepalive_timeout    20s;
  sendfile             on;
  tcp_nopush           on;
  gzip                 off;
  types_hash_max_size  4096;
  server {
    listen 80 default_server;
    return 444;
  }
  include sites/*.conf;
}
" > /etc/nginx/nginx.conf

mkdir -p "/srv/http/${hName}.test"
echo "<!DOCTYPE html>
<h1>Devbox: <em>${hName}</em></h1>
" > "/srv/http/${hName}.test/index.html"

chown -R dev:dev /srv/http

echo "server {
  listen      [::]:80;
  listen      80;
  server_name ${hName}.test;
  root        /srv/http/${hName}.test;
  access_log  off;
}
" > "/etc/nginx/sites/${hName}.test.conf"

systemctl enable nginx.service


echo "==> Done.
Please exit chroot, un-mount /mnt and reboot the VM.
Add '${vmIP} ${hName}.test' to your host machine's 'hosts' file.
Open http://${hName}.test in browser.
SSH to ${hName} with 'ssh -A dev@${hName}.test'
Mount files with 'sshfs -o idmap=user dev@${hName}.test:/srv/http /home/<you>/devbox'.
"
