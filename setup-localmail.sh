#!/bin/bash

echo "==> Install Postfix and Dovecot"
pacman -S postfix dovecot

echo "==> Set up Postfix"

echo "inet_interfaces = loopback-only
mynetworks_style = host
home_mailbox = Maildir/
canonical_maps = regexp:/etc/postfix/canonical-redirect" >> /etc/postfix/main.cf
echo "/^.*\$/ dev" > /etc/postfix/canonical-redirect

systemctl start postfix.service
systemctl enable postfix.service

echo "==> Set up Dovecot"

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

read -e -p "==> Install Mutt (cli email client)? (y/n): " cont
if [ "$cont" != "y" ]; then
  exit
fi

pacman -S mutt

echo "==> Done. You can read local mail with 'mutt -f ~/Maildir'."
