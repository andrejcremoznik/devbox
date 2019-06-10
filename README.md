# Devbox

Install and configure an Arch Linux VM for use as a web development environment.


## Instructions

1. Create a new VitualBox VM for Arch and boot it from the installation ISO
2. Install Arch following the installation guide (partition, mount, install base grub, configure hostname, locales, grub and reboot)
3. Copy the scripts to `/`
3. As root run `setup.sh` and any other `setup-*`s you need


### What does it do

1. Installs `openssh nginx git bash-completion unzip sudo`
2. Creates user `dev` and adds it to `sudoers`
4. Configures `.bashrc`
5. Configures network interfaces (dhcp and host-only)
6. Configures SSH daemon
7. Configures automatic time sync (you might want to change the servers in `/etc/systemd/timesyncd.conf` if you're not in Slovenia)
8. Limits Journal daemon log size
9. Configures Nginx, creates a `devbox.dev` host

Additionally:

* `setup-php.sh` will install and configure `php-fpm php-gd php-intl` and conditionally Composer and WP-CLI
* `setup-nodejs.sh` will install and configure `nodejs npm`
* `setup-mysql.sh` will install and configure `mariadb` and conditionally PHP support
* `setup-postgres.sh` will install and configure `postgresql` and conditionally PHP support
* `setup-localmail.sh` will install and configure `postfix` and `dovecot` for local mail delivery


## License - MIT

Copyright 2017-2019 Andrej Cremoznik

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
