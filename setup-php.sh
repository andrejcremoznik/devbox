#!/usr/bin/env bash

pacman -S --noconfirm php-fpm php-gd php-intl php-imagick

read -e -i "Europe/Amsterdam" -r -p "PHP timezone: " tz

echo "[PHP]
expose_php = On
max_execution_time = 20
max_input_time = 40
memory_limit = 256M
error_reporting = E_ALL
display_errors = On
post_max_size = 20M
upload_max_filesize = 10M

# Additional built-in extensions
extension = calendar.so
extension = exif.so
extension = gd.so
extension = gettext.so
extension = iconv.so
extension = intl.so

[Date]
date.timezone = \"${tz}\"" > /etc/php/conf.d/00-devbox.ini

echo "extension = imagick
imagick.skip_version_check = 1" > /etc/php/conf.d/imagick.ini

systemctl start php-fpm.service
systemctl enable php-fpm.service

echo "To enable PHP-FPM in Nginx vhost configuration add the following block to the server directive:

  location ~ \\.php\$ {
    try_files \$uri =404;
    fastcgi_index index.php;
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    fastcgi_pass unix:/run/php-fpm/php-fpm.sock;
  }
"

read -r -p "Install Composer and WP-CLI? (y/n): " withTools
[ "${withTools}" != "y" ] && { echo "==> Done."; exit 0; }

pacman -S --noconfirm composer

curl -o /home/dev/bin/wp -L https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod u+x /home/dev/bin/wp
chown dev:dev /home/dev/bin/wp

echo "==> Done."
