# Devbox

Install and configure an Arch Linux VM for use as a web development environment.


## Instructions

1. Create a new VitualBox VM for Arch ([requirements](#virtualbox-vm-configuration)) and boot it from the [installation ISO](https://archlinux.org/download/)
2. Sync time: `timedatectl set-ntp true`
3. With `fdisk /dev/sda` create a new DOS partition table and a new partition spanning full size
4. Format: `mkfs.ext4 /dev/sda1`
5. Mount: `mount /dev/sda1 /mnt`
6. Pacstrap: `pacstrap /mnt base linux-lts base-devel man-db man-pages texinfo nano grub`
7. Fstab: `genfstab -U /mnt >> /mnt/etc/fstab`
8. Chroot: `arch-chroot /mnt`
9. Download `setup.sh` and run it: `curl -O https://raw.githubusercontent.com/andrejcremoznik/devbox/master/setup.sh`

Run any other scripts for extra functionality.


### VirtualBox VM configuration

1. Configure basic things like memory, number of CPUs and a disk drive image. Decide on a reasonable disk growth limit, because expanding it afterwards is annoying.
2. Disable Audio and USB Controllers
3. Add 2 network adapters:
   1. Adapter 1: NAT
   2. Adapter 2: Host-only Adapter. Configure the Host-only adapter via File > Host Network Manager, create new adapter with IPv4 `10.10.0.1`, mask `255.255.255.0` and DHCP off.


## How to use the VM?

1. First make sure you've added the devbox's IP to your `hosts` file on your host machine e.g. `10.10.0.2 devbox.test`
2. Start it (headless mode recommended)
3. Connect to it via SSH: `dev@devbox.test`
4. Mount the filesystem from devbox to your host: `sshfs -o idmap=user dev@devbox.test:/srv/http /local/dir`
5. Create your projects in `/srv/http/*` and set up Nginx configurations in `/etc/nginx/sites/*`
6. Use `git`, `npm` and such on the devbox. No need for these tools on the host machine.


## License - MIT

Copyright 2017-2021 Andrej Cremoznik

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
