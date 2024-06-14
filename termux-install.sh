#!/data/data/com.termux/files/usr/bin/bash
#set -x
chmod +x "$0"

#termux 安装软件脚本

#todo
#calibre-web
#markdown-web
#gitbook
#chatgpt
#termux-api
#zerotier
#termux代理软件：v2ray singbox mihomo(clash.meta) dae crashshell 目前用magisk模块

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

install-update() {
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


install-ohmyzsh(){
sh -c "$(curl -fsSL https://install.ohmyz.sh/)"
git clone https://github.com/NvChad/starter ~/.config/nvim && nvim
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/0xProto.zip
unzip -o -d ~/.termux/ *.zip  
rm *.zip
cp font.ttf font.ttf.bak
cp .termux/0xProtoNerdFont-Regular.ttf font.ttf
read -p "结束，按回车键继续…" key
}

install-clouddrive2(){
curl -fsSL "https://mirror.ghproxy.com/https://github.com/kevin010717/clouddrive2/blob/main/cd2-termux.sh" | bash -s install root mirror
read -p "结束，按回车键继续…" key
}
start-clouddrive2(){
sudo nohup nsenter -t 1 -m -- /bin/bash -c "cd /data/data/com.termux/files/home/.clouddrive/ && sudo ./clouddrive" > /dev/null 2>&1 &
am start -a android.intent.action.VIEW -d http://$(get-local-ipv4-select):19798/ 
}

install-samba(){
mkdir $PREFIX/etc/samba
sed 's#@TERMUX_HOME@/storage/shared#/data/data/com.termux/files/home#g' /data/data/com.termux/files/usr/share/doc/samba/smb.conf.example > $PREFIX/etc/samba/smb.conf
pdbedit -a -u admin
read -p "结束，按回车键继续…" key
}
start-samba(){
smbclient -p 445 //127.0.0.1/internal -U admin
}

start-obs(){
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
}
start-yacd(){
am start -a android.intent.action.VIEW -d http://$(get-local-ipv4-select):9090/ui
}
start-gif(){
find . -type f \( -iname \*.mp4 -o -iname \*.mkv \) > file1.txt
mkdir -p img
while IFS= read -r file; do
  echo "处理文件 $(basename "$file")"
  #    read -p "按回车继续"
  #获取时长并分段
  filename="$file"
  duration=$(ffprobe -v quiet -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$filename") < /dev/null
  step=$(echo "$duration / 13" | bc -l)
  echo $duration
  echo $step
  #获取素材
  for f in $(seq 1 12)
  do
    step_int=$(printf "%.0f" $step)
    pos=$((step_int * f))
    ffmpeg -hide_banner -loglevel panic -ss "$pos" -t 2 -i "$file" -r 15 -vf "scale=500:-1" img/$f.gif -y < /dev/null
  done
  #拼接up素材
ffmpeg -hide_banner -loglevel panic -i img/1.gif -i img/2.gif -i img/3.gif -filter_complex "[0:v][1:v][2:v]concat=n=3:v=1:a=0[outv]" -map "[outv]" -strict -2 img/up.gif -y < /dev/null

#拼接down素材
ffmpeg -hide_banner -loglevel panic -i img/4.gif -i img/5.gif -i img/6.gif -filter_complex "[0:v][1:v][2:v]concat=n=3:v=1:a=0[outv]" -map "[outv]" -strict -2 img/down.gif -y < /dev/null

#拼接left素材
ffmpeg -hide_banner -loglevel panic -i img/7.gif -i img/8.gif -i img/9.gif -filter_complex "[0:v][1:v][2:v]concat=n=3:v=1:a=0[outv]" -map "[outv]" -strict -2 img/left.gif -y < /dev/null

#拼接right素材
ffmpeg -hide_banner -loglevel panic -i img/10.gif -i img/11.gif -i img/12.gif -filter_complex "[0:v][1:v][2:v]concat=n=3:v=1:a=0[outv]" -map "[outv]" -strict -2 img/right.gif -y < /dev/null

# 拼接素材
# ffmpeg -y -v warning -i img\up.gif -i img\down.gif -filter_complex "[0:v]pad=iw:ih*2[a];[a][1:v]overlay=0:h,fps=10,scale=-1:358" "%%~ni.gif"  
ffmpeg -hide_banner -loglevel panic -y -v warning -i img/up.gif -i img/down.gif -i img/left.gif -i img/right.gif -filter_complex "[0:v]pad=iw*2:ih*2[a];[a][1:v]overlay=0:h[b];[b][2:v]overlay=w:0[c];[c][3:v]overlay=w:h,fps=15,scale=600:-1" $(basename "${file%.*}").gif < /dev/null
#    echo " ">$(basename "${file%}")
done < file1.txt
rm -r file1.txt img
}
start-thumbnails(){
generate_thumbnail() {
  local video_file="$1"
  local thumbnail_file="${video_file%.*}.png"

  sudo ffmpeg -hide_banner -loglevel panic -y -i "$video_file" -frames 1 -vf "thumbnail,scale=1080:-1,tile=1X5:padding=10:color=white" "$thumbnail_file"
}

for video_file in *.mp4 *.mkv; do
  # 忽略非文件类型的东西（如目录）
  [[ -f "$video_file" ]] || continue

  echo "正在处理视频文件：$video_file"
  generate_thumbnail "$video_file"
done
}
start-git(){
git add .
git commit -m "1"
git push origin main
cp termux-install.sh $PREFIX/bin/termux-install
}

install-tmoe(){
bash -c "$(curl -L l.tmoe.me)"
}

install-mpv-termux-url-opener(){
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
start-termux-url-opener(){
 ~/bin/termux-url-opener
}

install-streamlink-biliup(){
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
start-biliup(){
mkdir .biliup && cd .biliup && biliup start
am start -a android.intent.action.VIEW -d http://$(get-local-ipv4-select):3000
}

install-filebrowser(){
mkdir .filebrowser
wget -O .filebrowser/filebrowser.tar.gz https://github.com/filebrowser/filebrowser/releases/download/v2.29.0/linux-arm64-filebrowser.tar.gz
tar -zxvf .filebrowser/filebrowser.tar.gz -C .filebrowser
chmod +x .filebrowser/filebrowser
read -p "结束，按回车键继续…" key
}
start-filebrowser(){
sudo nohup ~/.filebrowser/filebrowser -a 0.0.0.0 -p 18650 -r /data/data/com.termux/files -d ~/.filebrowser/filebrowser.db --disable-type-detection-by-header --disable-preview-resize --disable-exec --disable-thumbnails --cache-dir ~/.filebrowser/cache > /dev/null 2>&1 &
am start -a android.intent.action.VIEW -d http://$(get-local-ipv4-select):18650 
#nohup ~/.filebrowser/filebrowser -a 0.0.0.0 -p 18650 -r /data/data/com.termux/files > /dev/null 2>&1 &;;
}

install-aria2(){
 pkg install aria2
# aria2c --enable-rpc --rpc-listen-all 
 pkg install git nodejs
 git clone https://github.com/ziahamza/webui-aria2.git
 mv webui-aria2 .webui-aria2
read -p "结束，按回车键继续…" key
}
start-aria2(){
nohup node ~/.webui-aria2/node-server.js > /dev/null 2>&1 &
echo "访问https://zsxwz.com/go/?url=https://github.com/ngosang/trackerslist添加tracker"
am start -a android.intent.action.VIEW -d http://$(get-local-ipv4-select):8888 
} 

install-chfs(){
wget --no-check-certificate https://iscute.cn/tar/chfs/3.1/chfs-linux-arm64-3.1.zip
unzip chfs-linux-arm64-3.1.zip 
mv chfs-linux-arm64-3.1 chfs
mv chfs /data/data/com.termux/files/usr/bin/
rm chfs-linux-arm64-3.1.zip
read -p "结束，按回车键继续…" key
}
start-chfs(){
nohup sudo chfs --port=1234  > /dev/null 2>&1 &
am start -a android.intent.action.VIEW -d http://$(get-local-ipv4-select):1234
}

install-http-server(){
pkg install nodejs
npm install -g http-server
read -p "结束，按回车键继续…" key
}
start-http-sever(){
http-server -a 127.0.0.1 -p 8090
am start -a android.intent.action.VIEW -d http://$(get-local-ipv4-select):8090
}

install-qbittorrent(){
wget https://github.com/userdocs/qbittorrent-nox-static/releases/download/release-4.5.2_v2.0.8/aarch64-qbittorrent-nox
mv aarch64-qbittorrent-nox /data/data/com.termux/files/usr/bin/qbittorrent
chmod +x qbittorrent
read -p "结束，按回车键继续…" key
}
start-qbittorrent(){
sudo qbittorrent 
}

install-code-server(){
apt install tur-repo #安装软件源
apt install code-server #安装
read -p "结束，按回车键继续…" key
}
start-code-sever(){
cat ~/.config/code-server/config.yaml #查看密码
code-server
am start -a android.intent.action.VIEW -d http://$(get-local-ipv4-select):8080 
}

install-node-server(){
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

install-calibreweb(){
  pkg install python libxml2 libxslt pkg-config
  pip install cython wheel
  CFLAGS="-Wno-error=incompatible-function-pointer-types -O0" pip install lxml
  pkg i python-cryptography python-lxml
  pip install --user -U calibreweb 
  echo “export PATH="${HOME}/.local/bin:${PATH}"”> .bashrc && source .bashrc && echo $PATH
}
start-calibreweb(){
am start -a android.intent.action.VIEW -d http://$(get-local-ipv4-select):8083 
}
install(){
 while true
 do
  echo -e "${GREEN_COLOR}1.update${RES}"
  echo -e "${GREEN_COLOR}2.ohmyzsh${RES}"
  echo -e "${GREEN_COLOR}3.clouddrive2${RES}"
  echo -e "${GREEN_COLOR}4.samba${RES}"
  echo -e "${GREEN_COLOR}5.obs${RES}"
  echo -e "${GREEN_COLOR}6.mpv termux-url-opener${RES}"
  echo -e "${GREEN_COLOR}7.streamlink biliup${RES}"
  echo -e "${GREEN_COLOR}8.filebrowser${RES}"
  echo -e "${GREEN_COLOR}9.aria2${RES}"
  echo -e "${GREEN_COLOR}10.chfs${RES}"
  echo -e "${GREEN_COLOR}11.http-sever${RES}"
  echo -e "${GREEN_COLOR}12.qbittorrent${RES}"
  echo -e "${GREEN_COLOR}13.code-server${RES}"
  echo -e "${GREEN_COLOR}14.tmoe${RES}"
  read choice 
  case $choice in 
	1) install-update;;
	2) install-ohmyzsh;;
	3) install-clouddrive2;;
	4) install-samba;;
	5) install-obs;;
	6) install-mpv-termux-url-opener;;
	7) install-streamlink-biliup;;
	8) install-filebrowser;;
	9) install-aria2;;
	10) install-chfs;;
	11) install-http-server;;
	12) install-qbittorrent;;
	13) install-code-server;;
  14) install-tmoe;;
	*) break;;
  esac
 done
}
start(){
	while true
	do
		echo -e "${GREEN_COLOR}1.clouddrive2${RES}"
		echo -e "${GREEN_COLOR}2.filebrowser${RES}"
		echo -e "${GREEN_COLOR}3.yacd${RES}"
		echo -e "${GREEN_COLOR}4.aria2${RES}"
		echo -e "${GREEN_COLOR}5.qbittorrent${RES}"
		echo -e "${GREEN_COLOR}6.samba${RES}"
		echo -e "${GREEN_COLOR}7.termux-url-opener${RES}"
		echo -e "${GREEN_COLOR}8.obs${RES}"
		echo -e "${GREEN_COLOR}9.chfs${RES}"
		echo -e "${GREEN_COLOR}10.code-server${RES}"
		echo -e "${GREEN_COLOR}11.http-sever${RES}"
		echo -e "${GREEN_COLOR}12.biliup${RES}"
		echo -e "${GREEN_COLOR}13.thumbnails${RES}"
		echo -e "${GREEN_COLOR}14.gif${RES}"
		echo -e "${GREEN_COLOR}15.git${RES}"
		echo -e "${GREEN_COLOR}16.start-calibreweb${RES}"
		read choice 
		case $choice in 
		1) start-clouddrive2;;
  	2) start-filebrowser;;
    3) start-yacd;;
		4) start-aria2;;
		5) start-qbittorrent;;
    6) start-samba;;
		7) start-termux-url-opener;;
		8) start-obs;;
    9) start-chfs;;
		10) start-code-sever;;
		11) http-server ;;
		12) start-biliup;;
    13) start-thumbnails;;
    14) start-gif;;
    15) start-git;;
    16) start-calibreweb;;
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

pkg install cmatrix
#cmatrix

pkg install nyancat
#nyancat

pkg install nodejs
npm install mapscii -g
#mapscii

pkg install coreutils
#factor <target number>

pkg install figlet
#figlet <target string>

pkg install toilet
#toilet -f mono12 -F gay Kuan

pkg install weechat
#weechat
#/server add freenode8001 chat.freenode.net/8001
#/connect freenode8001
#/nick Kuan
#/join #termux

pkg install fortune
#fortune

pkg install cowsay
#cowsay -l

aptapt install sl
#sl

pkg install w3m
#w3m baidu.com

pkg install greed
#greed

pkg install moon-buggy
#moon-buggy

pkg install curl
#curl wttr.in/Beijin"

nano  $PREFIX/etc/motd
#修改启动问候语

pip install scrap_engine
git clone https://github.com/lxgr-linux/pokete.git
./pokete/pokete.py

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


