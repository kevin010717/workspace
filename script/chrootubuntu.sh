#!/bin/sh
export UBUNTUPATH="/data/data/com.termux/files/home/chrootubuntu"
su -c "busybox chroot "/data/data/com.termux/files/home/chrootubuntu" /bin/su - root -c '
echo \"nameserver 8.8.8.8\" > /etc/resolv.conf
echo \"127.0.0.1 localhost\" > /etc/hosts
groupadd -g 3003 aid_inet
groupadd -g 3004 aid_net_raw
groupadd -g 1003 aid_graphics
usermod -g 3003 -G 3003,3004 -a _apt
usermod -G 3003 -a root
apt update
apt upgrade
apt install vim net-tools sudo git
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
passwd root
groupadd storage
groupadd wheel
useradd -m -g users -G wheel,audio,video,storage,aid_inet -s /bin/bash user
passwd user
echo \"user ALL=(ALL:ALL) ALL\" | sudo tee -a /etc/sudoers
su user
#sudo apt install xubuntu-desktop
apt install kubuntu-desktop
update-alternatives --config x-terminal-emulator
apt-get autopurge snapd
cat <<EOF | sudo tee /etc/apt/preferences.d/nosnap.pref
# To prevent repository packages from triggering the installation of Snap,
# this file forbids snapd from being installed by APT.
# For more information: https://linuxmint-user-guide.readthedocs.io/en/latest/snap.html
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF
apt install software-properties-common
add-apt-repository ppa:mozillateam/ppa
apt-get update
apt-get install firefox-esr
'"
