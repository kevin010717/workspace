#!/bin/bash
apt update
#apt install xfce4 xfce4-goodies dbus-x11
apt install git sudo vim firefox-esr i3 dbus-x11 konsole kitty gnome-terminal -y
apt install i3 rofi picom feh kitty alacritty polybar pavucontrol flameshot
update-alternatives --config x-terminal-emulator
git clone --depth=1 https://github.com/adi1090x/polybar-themes.git ~/.config/polybar-themes && chmod +x ~/.config/polybar-themes/setup.sh && ~/.config/polybar-themes/setup.sh
git clone https://github.com/kevin010717/workspace.git ~/.workspace
passwd
groupadd storage
groupadd wheel
groupadd video
useradd -m -g users -G wheel,audio,video,storage -s /bin/bash user
passwd user
echo "user ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers
su user
