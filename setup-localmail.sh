#!/bin/bash

read "==> Install Postfix and Dovecot"
pacman -S postfix dovecot

read "==> Set up Postfix"

echo "inet_interfaces = loopback-only
mynetworks_style = host
home_mailbox = Maildir/
canonical_maps = regexp:/etc/postfix/canonical-redirect" >> /etc/postfix/main.cf
echo "/^.*\$/ dev" > /etc/postfix/canonical-redirect

systemctl start postfix.service
systemctl enable postfix.service

read "==> Set up Dovecot"

if [ -f /etc/dovecot/dovecot.conf ]; then
  mv /etc/dovecot/dovecot.conf /etc/dovecot/dovecot.conf.old
fi

echo "ssl = no
disable_plaintext_auth = no
passdb {
  args = dovecot
  driver = pam
}
userdb {
  driver = passwd
}
protocols = imap
mail_location = maildir:~/Maildir" > /etc/dovecot/dovecot.conf

newaliases

systemctl start dovecot.service
systemctl enable dovecot.service

read -e -p "==> Install Roundcube? (y/n): " cont
if [ "$cont" != "y" ]; then
  exit
fi

DIR=/srv/http/devbox.dev/roundcube

mkdir -p ${DIR}

curl -L https://github.com/roundcube/roundcubemail/tarball/master | tar zxf - --strip-components=1 -C ${DIR}

mysql -u root -pdev -e "CREATE DATABASE roundcube;"
echo "<?php
\$config = [
  'db_dsnw'                => 'mysql://root:dev@localhost/roundcube',
  'default_host'           => '127.0.0.1',
  'log_dir'                => 'logs/',
  'temp_dir'               => 'temp/',
  'product_name'           => 'Devbox Mail',
  'des_key'                => 'IAmNotARandomStringButWhoCares',
  'plugins'                => [],
  'language'               => 'en_US',
  'enable_spellcheck'      => false,
  'mime_param_folding'     => 0,
  'message_cache_lifetime' =>'1d',
  'mime_types'             => __DIR__ . '/mime.types',
  'create_default_folders' => true
];" > ${DIR}/config/config.inc.php
mysql -u root -pdev roundcube < ${DIR}/SQL/mysql.initial.sql
chmod a+rwx ${DIR}/logs ${DIR}/temp
wget -O ${DIR}/config/mime.types http://svn.apache.org/repos/asf/httpd/httpd/trunk/docs/conf/mime.types

echo "<li><a href=\"/roundcube/\">Roundcube</a> (dev / dev)</li>" >> /srv/http/devbox.dev/index.html

read "==> Fix file ownership"
chown -R dev:dev ${DIR}

read "==> Done"
