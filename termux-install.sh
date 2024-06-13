#!/data/data/com.termux/files/usr/bin/bash
#set -x

#termux 安装软件脚本

#todo
#termux代理软件：v2ray singbox mihomo(clash.meta) dae crashshell 目前用magisk模块
#termux-api
#chatgpt
#tmux + neovim + nvchad(lazyvim)
#创建git仓库
#bash -c "$(curl -L l.tmoe.me)"
#zerotier
#calibre-web
#markdown-web



RED_COLOR='\e[1;31m'
GREEN_COLOR='\e[1;32m'
YELLOW_COLOR='\e[1;33m'
BLUE_COLOR='\e[1;34m'
PINK_COLOR='\e[1;35m'
SHAN='\e[1;33;5m'
RES='\e[0m'
get-local-ipv4-using-hostname() {
  hostname -I 2>&- | awk '{print $1}'
}

# iproute2
get-local-ipv4-using-iproute2() {
  # OR ip route get 1.2.3.4 | awk '{print $7}'
  ip -4 route 2>&- | awk '{print $NF}' | grep -Eo --color=never '[0-9]+(\.[0-9]+){3}'
}

# net-tools
get-local-ipv4-using-ifconfig() {
  ( ifconfig 2>&- || ip addr show 2>&- ) | grep -Eo '^\s+inet\s+\S+' | grep -Eo '[0-9]+(\.[0-9]+){3}' | grep -Ev '127\.0\.0\.1|0\.0\.0\.0'
}

# 获取本机 IPv4 地址
get-local-ipv4() {
  set -o pipefail
  get-local-ipv4-using-hostname || get-local-ipv4-using-iproute2 || get-local-ipv4-using-ifconfig
}
get-local-ipv4-select() {
  local ips=$(get-local-ipv4)
  local retcode=$?
  if [ $retcode -ne 0 ]; then
      return $retcode
  fi
  grep -m 1 "^192\." <<<"$ips" || \
  grep -m 1 "^172\." <<<"$ips" || \
  grep -m 1 "^10\." <<<"$ips" || \
  head -n 1 <<<"$ips"
}

#1.update
install_update() {
echo "bell-character = ignore" >> ~/.termux/termux.properties
termux-reload-settings
termux-setup-storage
termux-change-repo
pkg update && pkg upgrade -y
pkg i root-repo x11-repo -y
pkg i openssh wget nethogs mc ranger nnn htop screen tmux ffmpeg tsu lux zsh gh git lazygit python-pip mpv iptables samba termux-services neovim nodejs -y
passwd
whoami
#del "C:\Users\admin\.ssh\known_hosts"
#ssh u0_a589@192.168.1.12 -p 8022
gh auth login
git config --global user.email "k511153362@gmail.com"
git config --global user.name "kevin010717"
git clone https://github.com/kevin010717/termux-install .termux-install
read -p "结束，按回车键继续…" key
}


#2.zsh
install_ohmyzsh(){
sh -c "$(curl -fsSL https://install.ohmyz.sh/)"
git clone https://github.com/NvChad/starter ~/.config/nvim && nvim
read -p "结束，按回车键继续…" key
}

#3.clouddrive2
install_clouddrive2(){
curl -fsSL "https://mirror.ghproxy.com/https://github.com/kevin010717/clouddrive2/blob/main/cd2-termux.sh" | bash -s install root mirror
read -p "结束，按回车键继续…" key
}

#4.samba
install_samba(){
mkdir $PREFIX/etc/samba
sed 's#@TERMUX_HOME@/storage/shared#/data/data/com.termux/files/home#g' /data/data/com.termux/files/usr/share/doc/samba/smb.conf.example > $PREFIX/etc/samba/smb.conf
pdbedit -a -u admin
read -p "结束，按回车键继续…" key
}

#5.obs
install_obs(){
echo << EOF > $PREFIX/bin/obs
#!/bin/sh
folder="/data/data/com.termux/files/home/video/" 
read -p "请输入您的推流地址和推流码(rtmp协议):" rtmp 
while true 
do
 cd $folder
 for video in $(ls *.mp4) 
 do
   echo "正在播放：${video}"
   echo $(date +%F%n%T)
   ffmpeg -re -i "$video" -preset ultrafast -vcodec libx264 -g 60 -b:v 2000k -c:a aac -b:a 128k -strict -2 -f flv ${rtmp} 
   #ffmpeg -re -i "$video" -i "$folder/image.jpg" -filter_complex overlay=W-w-5:5 -c:v libx264 -c:a aac -b:a 192k -strict -2 -f flv ${rtmp}
 done 
done
EOF
chmod +x $PREFIX/bin/obs
}

#6.mpv termux-url-opener
install_mpv_termux_url_opener(){
pip install youtube-dl yt-dlp you-get PySocks
#配置mpv
cp -r /data/data/com.termux/files/usr/share/doc/mpv ~/.config/
echo "volume-max=200" >> ~/.config/mpv/mpv.config
echo "script-opts=ytdl_hook-ytdl_path=/data/data/com.termux/files/usr/bin/yt-dlp" >> ~/.config/mpv/mpv.config
#配置termux-url-opener
mkdir -p ~/bin
echo 'echo "1.download it" 
      echo "2.listen to it"  
      read choice 
      case $choice in 
        1) yt-dlp --output "%(title)s.%(ext)s" --merge-output-format mp4 --embed-thumbnail --add-metadata -f "bestvideo[height<=1080]+bestaudio[ext=m4a]" $1;; 
        2) mpv --no-video -v $1;;
        *) mpv --no-video -v $1;;
      esac' >  ~/bin/termux-url-opener
read -p "结束，按回车键继续…" key
}

#7.streamlink biliup
install_streamlink_biliup(){
mkdir builds
cd builds/
git clone https://github.com/saghul/pycares
pip install setuptools
python setup.py install
cd ~
rm -r builds -y

pip install --user -U streamlink biliup
echo “export PATH="${HOME}/.local/bin:${PATH}"”> .bashrc && source .bashrc && echo $PATH

read -p "结束，按回车键继续…" key

}

#8.filebrowser
install_filebrowser(){
mkdir .filebrowser
wget -O .filebrowser/filebrowser.tar.gz https://github.com/filebrowser/filebrowser/releases/download/v2.29.0/linux-arm64-filebrowser.tar.gz
tar -zxvf .filebrowser/filebrowser.tar.gz -C .filebrowser
chmod +x .filebrowser/filebrowser
read -p "结束，按回车键继续…" key
}

#9.aria2
install_aria2(){
 pkg install aria2
# aria2c --enable-rpc --rpc-listen-all 
 pkg install git nodejs
 git clone https://github.com/ziahamza/webui-aria2.git
 mv webui-aria2 .webui-aria2
read -p "结束，按回车键继续…" key
}
 
#10.chfs
install_chfs(){
wget --no-check-certificate https://iscute.cn/tar/chfs/3.1/chfs-linux-arm64-3.1.zip
unzip chfs-linux-arm64-3.1.zip 
mv chfs-linux-arm64-3.1 chfs
mv chfs /data/data/com.termux/files/usr/bin/
rm chfs-linux-arm64-3.1.zip
read -p "结束，按回车键继续…" key
}

#11.http-sever
install_http_server(){
pkg install nodejs
npm install -g http-server
read -p "结束，按回车键继续…" key
}

#12.qbittorrent
install_qbittorrent(){
wget https://github.com/userdocs/qbittorrent-nox-static/releases/download/release-4.5.2_v2.0.8/aarch64-qbittorrent-nox
mv aarch64-qbittorrent-nox /data/data/com.termux/files/usr/bin/qbittorrent
chmod +x qbittorrent
read -p "结束，按回车键继续…" key
}

#13.code-server
install_code_server(){
apt install tur-repo #安装软件源
apt install code-server #安装
read -p "结束，按回车键继续…" key
}

#14.node.js开发服务器
install_node_server(){
mkdir nodeserver
cd nodeserver
npm init
npm install express --save

echo "const express = require('express');
const app = express();
app.get('/', (req, res) => {
   res.send('Hello World!');
});
app.listen(3000, () => {
   console.log('Server is running at http://localhost:3000');
});" > server.js

node server.js
}

install(){
 while true
 do
  echo  "${GREEN_COLOR}1.update${RES}"
  echo  "${GREEN_COLOR}2.ohmyzsh${RES}"
  echo  "${GREEN_COLOR}3.clouddrive2${RES}"
  echo  "${GREEN_COLOR}4.samba${RES}"
  echo  "${GREEN_COLOR}5.obs${RES}"
  echo  "${GREEN_COLOR}6.mpv termux-url-opener${RES}"
  echo  "${GREEN_COLOR}7.streamlink biliup${RES}"
  echo  "${GREEN_COLOR}8.filebrowser${RES}"
  echo  "${GREEN_COLOR}9.aria2${RES}"
  echo  "${GREEN_COLOR}10.chfs${RES}"
  echo  "${GREEN_COLOR}11.http-sever${RES}"
  echo  "${GREEN_COLOR}12.qbittorrent${RES}"
  echo  "${GREEN_COLOR}13.code-server${RES}"
  echo  "${GREEN_COLOR}0.shortcuts${RES}"
  read choice 
  case $choice in 
	1) install_update;;
	2) install_ohmyzsh;;
	3) install_clouddrive2;;
	4) install_samba;;
	5) install_obs;;
	6) install_mpv_termux_url_opener;;
	7) install_streamlink_biliup;;
	8) install_filebrowser;;
	9) install_aria2;;
	10) install_chfs;;
	11) install_http_server;;
	12) install_qbittorrent;;
	13) install_code_server;;
	0) install_shortcuts;;
	*) break;;
  esac
 done
}
start(){
	while true
	do
		echo  -e "${GREEN_COLOR}1.openssh${RES}"
		echo  "${GREEN_COLOR}2.clouddrive2${RES}"
		echo  "${GREEN_COLOR}3.samba${RES}"
		echo  "${GREEN_COLOR}4.obs${RES}"
		echo  "${GREEN_COLOR}5.mpv termux-url-opener${RES}"
		echo  "${GREEN_COLOR}6.streamlink biliup${RES}"
		echo  "${GREEN_COLOR}7.filebrowser${RES}"
		echo  "${GREEN_COLOR}8.aria2${RES}"
		echo  "${GREEN_COLOR}9.chfs${RES}"
		echo  "${GREEN_COLOR}10.http-sever${RES}"
		echo  "${GREEN_COLOR}11.qbittorrent${RES}"
		echo  "${GREEN_COLOR}12.code-server${RES}"
		read choice 
		case $choice in 
		1) sshd;;
		2) sudo nsenter -t 1 -m -- /bin/bash -c "cd /data/data/com.termux/files/home/.clouddrive/ && sudo ./clouddrive"
       echo "访问地址：${GREEN_COLOR}http://$(get-local-ipv4-select):19798/${RES}\r\n"
       am start -a android.intent.action.VIEW -d http://$(get-local-ipv4-select):19798/ ;;
		3) smbclient -p 445 //127.0.0.1/internal -U admin;;
		4) obs;;
		5) ~/bin/termux-url-opener;;
		6) mkdir .biliup && cd .biliup && biliup start;;
		7) sudo nohup ~/.filebrowser/filebrowser -a 0.0.0.0 -p 18650 -r /data/data/com.termux/files -d ~/.filebrowser/filebrowser.db --disable-type-detection-by-header --disable-preview-resize --disable-exec --disable-thumbnails --cache-dir ~/.filebrowser/cache > /dev/null 2>&1 &;;
		   #nohup ~/.filebrowser/filebrowser -a 0.0.0.0 -p 18650 -r /data/data/com.termux/files > /dev/null 2>&1 &;;
		8) node ~/.webui-aria2/node-server.js
		   echo "访问https://zsxwz.com/go/?url=https://github.com/ngosang/trackerslist添加tracker";;
		9) chfs --port=1234 ;;
		10) http-server ;;
		11) sudo qbittorrent ;;
		12) cat ~/.config/code-server/config.yaml #查看密码
		  	code-server ;;
		*) break;;
		  esac
	done
}

while true
do
  echo  -e "${GREEN_COLOR}1.install${RES}"
  echo  -e "${GREEN_COLOR}2.start${RES}"
  read choice
  case $choice in
    1)install;;
    2) start;;
    *) break;;
  esac
done

#有趣的小程序
cat << EOF > $PREFIX/bin/cheet
#!/bin/sh
echo "

apt install cmatrix
#cmatrix

pkg install nyancat
#nyancat

pkg install nodejs
npm install mapscii -g
#mapscii

pkg install coreutils
#factor <target number>

apt install figlet
#figlet <target string>

apt install toilet
#toilet -f mono12 -F gay Kuan

apt install weechat
#weechat
#/server add freenode8001 chat.freenode.net/8001
#/connect freenode8001
#/nick Kuan
#/join #termux

apt install fortune
#fortune

apt install cowsay
#cowsay -l

apt install sl
#sl

apt install w3m
#w3m baidu.com

apt install greed
#greed

apt install moon-buggy
#moon-buggy

apt install curl
#curl wttr.in/Beijin"

nano  $PREFIX/etc/motd
#修改启动问候语

pip install scrap_engine
git clone https://github.com/lxgr-linux/pokete.git
./pokete/pokete.py
echo $HOME
echo $PREFIX
echo $TMPPREFIX
EOF
chmod +x $PREFIX/bin/cheet



: <<'END_COMMENT'
#5 kodbox
pkg install nginx php php-fpm -y
配置方法：
nano $PREFIX/etc/php-fpm.d/www.conf
#找到：listen = /data/data/com.termux/files/usr/var/run/php-fpm.sock修改为: listen = 127.0.0.1:9000
nano $PREFIX/etc/nginx/nginx.conf
#找到index index.html index.htm;修改为: index index.html index.htm index.php;
#去掉注释并修改为
location ~ \.php$ {
    root           html;
    fastcgi_pass   127.0.0.1:9000;
    fastcgi_index  index.php;
    fastcgi_param  SCRIPT_FILENAME  /data/data/com.termux/files/usr/share/nginx/html$fastcgi_script_name;
    include        fastcgi_params;
}
sudo lsof -i :8080 :9000
kill <pid>
php-fpm
nginx
cd $PREFIX/share/nginx/html
mkdir kod
cd kod
wget https://static.kodcloud.com/update/download/kodbox.1.35.zip
unzip kodbox.1.35.zip && chmod -Rf 777 ./*
#直接访问127.0.0.1:8080/kod
echo "kodbox安装结束，按回车键继续…"
read -p ""
END_COMMENT


