#!/bin/bash
#tsinghua sources
apt update && apt install ca-certificates -y
apt autopurge snapd
mv /etc/apt/sources.list /etc/apt/sources.list.bak
touch /etc/apt/sources.list && cat <<EOF >> /etc/apt/sources.list
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ noble main universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ noble-updates main universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ noble-security main universe multiverse
EOF
apt install software-properties-common -y && add-apt-repository ppa:mozillateam/ppa && apt update && apt install firefox-esr
apt install zsh -y && sh -c "$(curl -fsSL https://install.ohmyz.sh/)" && chsh -s $(which zsh)
wget -O .yazi.zip https://github.com/sxyazi/yazi/releases/download/nightly/yazi-aarch64-unknown-linux-gnu.zip && unzip .yazi.zip -d /usr/bin/ && cp /usr/bin/yazi-aarch64-unknown-linux-gnu/yazi /usr/bin/yazi

passwd
groupadd storage
groupadd wheel
groupadd video
useradd -m -g users -G wheel,audio,video,storage -s /bin/bash user
passwd user
echo "user ALL=(ALL:ALL) ALL" >> /etc/sudoers
su user
cd

#apt install xubuntu-desktop
#apt install kubuntu-desktop
#apt install ubuntu-desktop
apt install git sudo vim i3 dbus-x11 konsole kitty gnome-terminal -y
apt install i3 rofi picom feh kitty alacritty polybar pavucontrol flameshot -y
update-alternatives --config x-terminal-emulator
git clone --depth=1 https://github.com/adi1090x/polybar-themes.git ~/.config/polybar-themes && chmod +x ~/.config/polybar-themes/setup.sh && ~/.config/polybar-themes/setup.sh
git clone https://github.com/kevin010717/workspace.git ~/.workspace
