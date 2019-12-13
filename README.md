# Devbox

Install and configure an Arch Linux VM for use as a web development environment.


## Instructions

1. Create a new VitualBox VM for Arch and boot it from the installation ISO
2. Install Arch following the installation guide (partition, mount, install, configure hostname, locales, bootloader, network* and reboot)
3. Copy the scripts to `/`
4. As root run `setup.sh` and any other `setup-*`s you need


### VirtualBox VM configuration

1. Configure basic things like memory, number of CPUs and a disk drive image. Decide on a reasonable disk growth limit, because expanding it afterwards is annoying.
2. Disable Audio or USB Controllers
3. Add 2 Network adapters:
   1. Adapter 1: NAT
   2. Adapter 2: Host-only Adapter. Configure the Host-only adapter via File > Host Network Manager, create new adapter with IPv4 `10.10.0.1`, mask `255.255.255.0` and DHCP off.


### Configure networks on guest

Get the names of the adapters with `ip link show` (example names `enp0s3`, `enp0s8`).
Create configuration to use them via `systemd-networkd`.

1. DHCP for internet access `/etc/systemd/network/dhcp.network`:
   ```
   [Match]
   Name=enp0s3 # This is the NAT adapter
   [Network]
   DHCP=ipv4
   ```
2. DHCP for internet access `/etc/systemd/network/host.network`:
   ```
   [Match]
   Name=enp0s8 # This is the Host-only adapter
   [Network]
   Address=10.10.0.2/24 # 10.10.0.2 will be the IP of the guest.
   ```
3. Enable associated services:
   ```
   systemctl enable systemd-networkd.service
   systemctl enable systemd-resolved.service
   ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
   ```

## What does it do

1. Installs `openssh nginx git bash-completion unzip sudo`
2. Creates user `dev` and adds it to `sudoers`
4. Configures `.bashrc`
5. Configures SSH daemon
6. Configures automatic time sync (you might want to change the servers in `/etc/systemd/timesyncd.conf`)
7. Limits Journal daemon log size
8. Configures Nginx, creates a `<your hostname>.test` host

Additionally:

* `setup-php.sh` will install and configure `php-fpm php-gd php-intl` and conditionally Composer and WP-CLI
* `setup-nodejs.sh` will install and configure `nodejs npm`
* `setup-mysql.sh` will install and configure `mariadb` and conditionally PHP support
* `setup-postgres.sh` will install and configure `postgresql` and conditionally PHP support
* `setup-localmail.sh` will install and configure `postfix` and `dovecot` for local mail delivery


## License - MIT

Copyright 2017-2020 Andrej Cremoznik

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
