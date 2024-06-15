#!/bin/bash
sudo passwd root
sudo passwd -u root
su -

sudo apt update
sudo apt install curl neovim git zsh net-tools tmux openssh-server -y
sh -c "$(curl -fsSL https://install.ohmyz.sh/)"
sudo usermod -s /usr/bin/zsh ${whoami}
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/0xProto.zip
unzip *.zip
rm -rf *.zip
sudo cp 0xProtoNerdFont-Regular.ttf /usr/share/fonts
fc-cache -fv
#todo : 字体切换
git clone https://github.com/NvChad/starter ~/.config/nvim && nvim

wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb
google-chrome

bash -c "$(curl -kfsSl --resolve raw.githubusercontent.com:443:199.232.68.133 https://raw.githubusercontent.com/juewuy/ShellClash/master/install.sh)" && source /etc/profile &> /dev/null

sudo systemctl status ssh

curl -s https://install.zerotier.com | sudo bash
sudo systemctl start zerotier-one
sudo zerotier-cli join 8056c2e21c28950a
