#!/usr/bin/env bash

echo "==> Install PHP-FPM"
pacman -Sy php-fpm php-gd php-intl

echo "==> Set up PHP"
echo "[PHP]
expose_php = On
max_execution_time = 20
max_input_time = 40
memory_limit = 256M
error_reporting = E_ALL
display_errors = On
post_max_size = 20M
upload_max_filesize = 10M

extension=calendar.so
extension=exif.so
extension=gd.so
extension=gettext.so
extension=iconv.so
extension=intl.so

[Date]
date.timezone = \"Europe/Ljubljana\"
" > /etc/php/conf.d/00-devbox.ini

systemctl start php-fpm.service
systemctl enable php-fpm.service

read -e -p "Install Composer and WP-CLI? (y/n): " withTools
if [ "$withTools" != "y" ]; then
  echo "==> Done."
  exit
fi

pacman -S composer

curl -o /home/dev/bin/wp -L https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod u+x /home/dev/bin/wp
chown dev:dev /home/dev/bin/wp

echo "==> Done."
