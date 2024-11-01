#!/bin/bash
apt autopurge snapd
apt update
apt install sudo vim software-properties-common
sudo add-apt-repository ppa:mozillateam/ppa && sudo apt update && sudo apt install firefox-esr
sudo sed -i 's/ports.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list
