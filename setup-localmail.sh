#!/usr/bin/env bash

echo "==> Install Postfix and Dovecot"
pacman -Sy postfix dovecot

echo "==> Set up Postfix"
echo "inet_interfaces = loopback-only
mynetworks_style = host
home_mailbox = Maildir/
canonical_maps = regexp:/etc/postfix/canonical-redirect
" >> /etc/postfix/main.cf
echo "/^.*\$/ dev
" > /etc/postfix/canonical-redirect

systemctl start postfix.service
systemctl enable postfix.service

echo "==> Set up Dovecot"
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
mail_location = maildir:~/Maildir
" > /etc/dovecot/dovecot.conf

newaliases

systemctl start dovecot.service
systemctl enable dovecot.service

read -e -p "==> Install Mutt? (y/n): " withMutt
if [ "$withMutt" != "y" ]; then
  echo "==> Done."
  exit
fi

pacman -S mutt

echo "==> Done. You can read local mail with 'mutt -f ~/Maildir'."
