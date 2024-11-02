#!/bin/bash
  read -p "root?(y/n):" choice
  case $choice in
    y)
      apt update && apt install ca-certificates sudo vim software-properties-common -y
      mv /etc/apt/sources.list /etc/apt/sources.list.bak
      cat <<EOF >> /etc/apt/sources.list
      deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ noble main universe multiverse
      deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ noble-updates main universe multiverse
      deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports/ noble-security main universe multiverse
      EOF
      apt update
      passwd
      groupadd storage && groupadd wheel && groupadd video
      useradd -m -g users -G wheel,audio,video,storage -s /bin/bash user
      passwd user
      echo "user ALL=(ALL:ALL) ALL" >> /etc/sudoers
      su user
      ;;
    n)
      cd ~
      sudo apt autopurge snapd
      sudo add-apt-repository ppa:mozillateam/ppa &&sudo  apt update &&sudo apt install firefox-esr -y
      sudo apt install zsh -y && sh -c "$(curl -fsSL https://install.ohmyz.sh/)" 
      chsh -s $(which zsh)
      sudo apt install vlc libreoffice glmark2 -y
      wget -O ~/.yazi.zip https://github.com/sxyazi/yazi/releases/download/nightly/yazi-aarch64-unknown-linux-gnu.zip && unzip ~/.yazi.zip -d /usr/bin/ && cp /usr/bin/yazi-aarch64-unknown-linux-gnu/yazi /usr/bin/yazi
      git clone https://github.com/LazyVim/starter ~/.config/nvim && nvim
      git clone https://github.com/kevin010717/workspace.git ~/.workspace
      cp -rf ~/.workspace/.config/ ~/ 
      cp -rf ~/.workspace/.config/.zshrc ~/.zshrc
      #apt install xubuntu-desktop
      #apt install kubuntu-desktop
      #apt install ubuntu-desktop
      sudo apt install git sudo vim i3 dbus-x11 konsole kitty gnome-terminal -y
      sudo apt install i3 rofi picom feh kitty alacritty polybar pavucontrol flameshot -y
      sudo update-alternatives --config x-terminal-emulator
      git clone --depth=1 https://github.com/adi1090x/polybar-themes.git ~/.config/polybar-themes && chmod +x ~/.config/polybar-themes/setup.sh && ~/.config/polybar-themes/setup.sh
      ;;
  esac


