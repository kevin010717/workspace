#!/bin/bash
apt update
apt install sudo vim firefox-esr
passwd
groupadd storage
groupadd wheel
groupadd video
useradd -m -g users -G wheel,audio,video,storage -s /bin/bash user
passwd user
echo "user ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers
su user
sudo apt install xfce4 xfce4-goodies dbus-x11

