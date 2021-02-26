#!/usr/bin/env bash

# Install PHP7 version of all installed PHP packages
pacman -Qqs ^php7 && { echo "PHP7 is already installed. Exiting..."; exit 1; }
pacman -Qqs ^php | sed "s/php/php7/" | pacman -S -

# Copy configs for PHP7 from default PHP
mkdir -p /etc/php7/conf.d
cp -fr /etc/php/conf.d/* /etc/php7/conf.d/

# Start and enable PHP-FPM7
systemctl start php-fpm7.service
systemctl enable php-fpm7.service

echo "To enable PHP-FPM7 in Nginx vhost configuration add the following block to the server directive:

  location ~ \\.php\$ {
    try_files \$uri =404;
    fastcgi_index index.php;
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    fastcgi_pass unix:/run/php-fpm7/php-fpm.sock;
  }

The configuration for PHP7 had been copied over from the default PHP installation.
Default config: /etc/php/conf.d/
PHP7 config:    /etc/php7/conf.d/

==> Done."
