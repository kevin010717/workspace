#!/data/data/com.termux/files/usr/bin/bash
#set -x
chmod +x "$0"

RED_COLOR='\e[1;31m'
GREEN_COLOR='\e[1;32m'
YELLOW_COLOR='\e[1;33m'
BLUE_COLOR='\e[1;34m'
PINK_COLOR='\e[1;35m'
SHAN='\e[1;33;5m'
RES='\e[0m'

#todo
#calibre-web
#markdown-web
#gitbook
#chatgpt
#termux-api
#zerotier
#termux代理软件：v2ray singbox mihomo(clash.meta) dae crashshell 目前用magisk模块

install_update() {
  echo "bell-character = ignore" >>~/.termux/termux.properties
  termux-reload-settings
  termux-setup-storage
  termux-change-repo
  pkg update && pkg upgrade -y
  pkg i root-repo x11-repo -y
  pkg i rxfetch rust lazygit peaclock tty-clock android-tools openssh wget nethogs mc ranger nnn htop screen tmux ffmpeg tsu lux zsh gh git lazygit python-pip mpv iptables samba termux-services neovim nodejs bk slides glow tree neofetch -y
  pkg i cmatrix nyancat coreutils figlet toilet weechat fortune cowsay sl w3m greed moon-buggy -y
  curl -o termux-api.apk https://f-droid.org/repo/com.termux.api_51.apk
  wget -O termux-styling.apk https://f-droid.org/repo/com.termux.styling_1000.apk
  su -c pm install termux-api.apk termux-styling.apk
  rm termux-api.apk termux-styling.apk
  #npm install mapscii -g
  #cargo install clock-tui bk
  #pip install epr-reader

  passwd
  whoami
  ssh-keygen -t rsa
  #cd .ssh
  #ssh-copy-id -i id_rsa.pub kevin@10.147.17.140
  #del "C:\Users\admin\.ssh\known_hosts"
  #ssh u0_a589@192.168.1.12 -p 8022

  git config --global user.email "k511153362@gmail.com"
  git config --global user.name "kevin010717"
  gh auth login

  ranger --copy-config=all
  export RANGER_LOAD_DEFAULT_RC=FALSE
  #mime ^text,  label editor = nvim -- "$@"

  #bash -c "$(curl -L l.tmoe.me)"
  #mytermux.git
  read -p "结束，按回车键继续…" key
}

install_ohmyzsh() {
  sh -c "$(curl -fsSL https://install.ohmyz.sh/)"
  #git clone https://github.com/NvChad/starter ~/.config/nvim && nvim
  git clone https://github.com/LazyVim/starter ~/.config/nvim
  #echo "neofetch" >>~/.zshrc
  echo "rxfetch" >>~/.zshrc
  echo "sshd" >>~/.zshrc
  echo 'alias nv="nvim"' >>~/.aliases
  echo 'alias ra="ranger"' >>~/.aliases
  echo 'alias gitacp="git add . ; git commit -m "1" ;git push origin main"' >>~/.aliases
  source ~/.zshrc ~/.aliases
  read -p "结束，按回车键继续…" key
}

install_clouddrive2() {
  curl -fsSL "https://mirror.ghproxy.com/https://github.com/kevin010717/clouddrive2/blob/main/cd2-termux.sh" | bash -s install root mirror
  read -p "结束，按回车键继续…" key
}

install_mpv_termux_url_opener() {
  pip install youtube-dl yt-dlp you-get PySocks
  #配置mpv
  cp -r /data/data/com.termux/files/usr/share/doc/mpv ~/.config/
  echo "volume-max=200" >>~/.config/mpv/mpv.conf
  echo "script-opts=ytdl_hook-ytdl_path=/data/data/com.termux/files/usr/bin/yt-dlp" >>~/.config/mpv/mpv.conf
  #配置termux-url-opener
  mkdir -p ~/bin
  echo 'echo "1.download it" 
  echo "2.listen to it"  
  read choice 
  case $choice in 
  1) yt-dlp --output "%(title)s.%(ext)s" --merge-output-format mp4 --embed-thumbnail --add-metadata -f "bestvideo[height<=1080]+bestaudio[ext=m4a]" $1;; 
  2) mpv --no-video -v $1;;
  *) mpv --no-video -v $1;;
esac' >~/bin/termux-url-opener
  read -p "结束，按回车键继续…" key
}

install_samba() {
  mkdir $PREFIX/etc/samba
  sed 's#@TERMUX_HOME@/storage/shared#/data/data/com.termux/files/home#g' /data/data/com.termux/files/usr/share/doc/samba/smb.conf.example >$PREFIX/etc/samba/smb.conf
  pdbedit -a -u admin
  read -p "结束，按回车键继续…" key
}

install_streamlink_biliup() {
  mkdir builds
  cd builds/
  git clone https://github.com/saghul/pycares
  pip install setuptools
  python setup.py install
  cd ~
  rm -r builds -y

  pip install --user -U streamlink biliup
  echo “export PATH="${HOME}/.local/bin:${PATH}"” >.bashrc && source .bashrc && echo $PATH
  read -p "结束，按回车键继续…" key
}

install_filebrowser() {
  mkdir .filebrowser
  wget -O .filebrowser/filebrowser.tar.gz https://github.com/filebrowser/filebrowser/releases/download/v2.29.0/linux-arm64-filebrowser.tar.gz
  tar -zxvf .filebrowser/filebrowser.tar.gz -C .filebrowser
  chmod +x .filebrowser/filebrowser
  read -p "结束，按回车键继续…" key
}

install_aria2() {
  pkg install aria2
  # aria2c --enable-rpc --rpc-listen-all
  pkg install git nodejs
  git clone https://github.com/ziahamza/webui-aria2.git
  mv webui-aria2 .webui-aria2
  echo "访问https://zsxwz.com/go/?url=https://github.com/ngosang/trackerslist添加tracker"
  read -p "结束，按回车键继续…" key
}

install_chfs() {
  wget --no-check-certificate https://iscute.cn/tar/chfs/3.1/chfs-linux-arm64-3.1.zip
  unzip chfs-linux-arm64-3.1.zip
  mv chfs-linux-arm64-3.1 chfs
  mv chfs /data/data/com.termux/files/usr/bin/
  rm chfs-linux-arm64-3.1.zip
  read -p "结束，按回车键继续…" key
}

install_http_server() {
  pkg install nodejs
  npm install -g http-server
  read -p "结束，按回车键继续…" key
}

install_qbittorrent() {
  wget https://github.com/userdocs/qbittorrent-nox-static/releases/download/release-4.5.2_v2.0.8/aarch64-qbittorrent-nox
  mv aarch64-qbittorrent-nox /data/data/com.termux/files/usr/bin/qbittorrent
  chmod +x qbittorrent
  read -p "结束，按回车键继续…" key
}

install_code_server() {
  apt install tur-repo    #安装软件源
  apt install code-server #安装
  read -p "结束，按回车键继续…" key
}

install_node_server() {
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
});" >server.js

  node server.js
}

install_calibreweb() {
  pip install --user -U calibreweb
}

install_leetcode_cli() {
  npm install -g leetcode-cli
}
install() {
  while true; do
    echo -e "${GREEN_COLOR}1.update${RES}"
    echo -e "${GREEN_COLOR}2.ohmyzsh${RES}"
    echo -e "${GREEN_COLOR}3.clouddrive2${RES}"
    echo -e "${GREEN_COLOR}4.mpv-termux-url-opener${RES}"
    echo -e "${GREEN_COLOR}5.samba${RES}"
    echo -e "${GREEN_COLOR}7.streamlink biliup${RES}"
    echo -e "${GREEN_COLOR}8.filebrowser${RES}"
    echo -e "${GREEN_COLOR}9.aria2${RES}"
    echo -e "${GREEN_COLOR}10.chfs${RES}"
    echo -e "${GREEN_COLOR}11.http-sever${RES}"
    echo -e "${GREEN_COLOR}12.qbittorrent${RES}"
    echo -e "${GREEN_COLOR}13.code-server${RES}"
    echo -e "${GREEN_COLOR}15.all${RES}"
    read choice
    case $choice in
    1) install_update ;;
    2) install_ohmyzsh ;;
    3) install_clouddrive2 ;;
    4) install_mpv_termux_url_opener ;;
    5) install_samba ;;
    7) install_streamlink_biliup ;;
    8) install_filebrowser ;;
    9) install_aria2 ;;
    10) install_chfs ;;
    11) install_http_server ;;
    12) install_qbittorrent ;;
    13) install_code_server ;;
    *) break ;;
    esac
  done
}

start_obs() {
  folder="/data/data/com.termux/files/home/video/"
  read -p "请输入您的推流地址和推流码(rtmp协议):" rtmp
  while true; do
    cd $folder
    for video in $(ls *.mp4); do
      echo "正在播放：${video}"
      echo $(date +%F%n%T)
      ffmpeg -re -i "$video" -preset ultrafast -vcodec libx264 -g 60 -b:v 2000k -c:a aac -b:a 128k -strict -2 -f flv ${rtmp}
      #ffmpeg -re -i "$video" -i "$folder/image.jpg" -filter_complex overlay=W-w-5:5 -c:v libx264 -c:a aac -b:a 192k -strict -2 -f flv ${rtmp}
    done
  done
}

start_gif() {
  find . -type f \( -iname \*.mp4 -o -iname \*.mkv \) >file1.txt
  mkdir -p img
  while IFS= read -r file; do
    echo "处理文件 $(basename "$file")"
    #    read -p "按回车继续"
    #获取时长并分段
    filename="$file"
    duration=$(ffprobe -v quiet -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$filename") </dev/null
    step=$(echo "$duration / 13" | bc -l)
    echo $duration
    echo $step
    #获取素材
    for f in $(seq 1 12); do
      step_int=$(printf "%.0f" $step)
      pos=$((step_int * f))
      ffmpeg -hide_banner -loglevel panic -ss "$pos" -t 2 -i "$file" -r 15 -vf "scale=500:-1" img/$f.gif -y </dev/null
    done
    #拼接up素材
    ffmpeg -hide_banner -loglevel panic -i img/1.gif -i img/2.gif -i img/3.gif -filter_complex "[0:v][1:v][2:v]concat=n=3:v=1:a=0[outv]" -map "[outv]" -strict -2 img/up.gif -y </dev/null

    #拼接down素材
    ffmpeg -hide_banner -loglevel panic -i img/4.gif -i img/5.gif -i img/6.gif -filter_complex "[0:v][1:v][2:v]concat=n=3:v=1:a=0[outv]" -map "[outv]" -strict -2 img/down.gif -y </dev/null

    #拼接left素材
    ffmpeg -hide_banner -loglevel panic -i img/7.gif -i img/8.gif -i img/9.gif -filter_complex "[0:v][1:v][2:v]concat=n=3:v=1:a=0[outv]" -map "[outv]" -strict -2 img/left.gif -y </dev/null

    #拼接right素材
    ffmpeg -hide_banner -loglevel panic -i img/10.gif -i img/11.gif -i img/12.gif -filter_complex "[0:v][1:v][2:v]concat=n=3:v=1:a=0[outv]" -map "[outv]" -strict -2 img/right.gif -y </dev/null

    # 拼接素材
    # ffmpeg -y -v warning -i img\up.gif -i img\down.gif -filter_complex "[0:v]pad=iw:ih*2[a];[a][1:v]overlay=0:h,fps=10,scale=-1:358" "%%~ni.gif"
    ffmpeg -hide_banner -loglevel panic -y -v warning -i img/up.gif -i img/down.gif -i img/left.gif -i img/right.gif -filter_complex "[0:v]pad=iw*2:ih*2[a];[a][1:v]overlay=0:h[b];[b][2:v]overlay=w:0[c];[c][3:v]overlay=w:h,fps=15,scale=600:-1" $(basename "${file%.*}").gif </dev/null
    #    echo " ">$(basename "${file%}")
  done <file1.txt
  rm -r file1.txt img
}
start_thumbnails() {
  start_generate_thumbnail() {
    local video_file="$1"
    local thumbnail_file="${video_file%.*}.png"

    sudo ffmpeg -hide_banner -loglevel panic -y -i "$video_file" -frames 1 -vf "thumbnail,scale=1080:-1,tile=1X5:padding=10:color=white" "$thumbnail_file"
  }

  for video_file in *.mp4 *.mkv; do
    # 忽略非文件类型的东西（如目录）
    [[ -f "$video_file" ]] || continue

    echo "正在处理视频文件：$video_file"
    start_generate_thumbnail "$video_file"
  done
}
start() {
  while true; do
    echo -e "${GREEN_COLOR}1.clouddrive2${RES}"
    echo -e "${GREEN_COLOR}2.filebrowser${RES}"
    echo -e "${GREEN_COLOR}3.yacd${RES}"
    echo -e "${GREEN_COLOR}4.aria2${RES}"
    echo -e "${GREEN_COLOR}5.qbittorrent${RES}"
    echo -e "${GREEN_COLOR}6.samba${RES}"
    echo -e "${GREEN_COLOR}7.termux-url-opener${RES}"
    echo -e "${GREEN_COLOR}9.chfs${RES}"
    echo -e "${GREEN_COLOR}10.code-server${RES}"
    echo -e "${GREEN_COLOR}11.http-sever${RES}"
    echo -e "${GREEN_COLOR}12.biliup${RES}"
    echo -e "${GREEN_COLOR}13.calibreweb${RES}"
    echo -e "${GREEN_COLOR}14.obs${RES}"
    echo -e "${GREEN_COLOR}15.gif${RES}"
    echo -e "${GREEN_COLOR}16.thumnails${RES}"

    read choice
    case $choice in
    1)
      sudo nohup nsenter -t 1 -m -- /bin/bash -c "cd /data/data/com.termux/files/home/.clouddrive/ && sudo ./clouddrive" >/dev/null 2>&1 &
      am start -a android.intent.action.VIEW -d http://127.0.0.1:19798/
      ;;
    2)
      sudo nohup ~/.filebrowser/filebrowser -a 0.0.0.0 -p 18650 -r /data/data/com.termux/files -d ~/.filebrowser/filebrowser.db --disable-type-detection-by-header --disable-preview-resize --disable-exec --disable-thumbnails --cache-dir ~/.filebrowser/cache >/dev/null 2>&1 &
      am start -a android.intent.action.VIEW -d http://127.0.0.1:18650
      ;;
      #nohup ~/.filebrowser/filebrowser -a 0.0.0.0 -p 18650 -r /data/data/com.termux/files > /dev/null 2>&1 &;;
    3)
      am start -a android.intent.action.VIEW -d http://127.0.0.1:9090/ui
      ;;
    4)
      nohup node ~/.webui-aria2/node-server.js >/dev/null 2>&1 &
      am start -a android.intent.action.VIEW -d http://127.0.0.1:8888
      ;;
    5)
      sudo qbittorrent
      ;;
    6)
      smbclient -p 445 //127.0.0.1/internal -U admin
      ;;
    7)
      ~/bin/termux-url-opener
      ;;
    9)
      nohup sudo chfs --port=1234 >/dev/null 2>&1 &
      am start -a android.intent.action.VIEW -d http://127.0.0.1:1234
      ;;
    10)
      cat ~/.config/code-server/config.yaml #查看密码
      code-server
      am start -a android.intent.action.VIEW -d http://127.0.0.1:8080
      ;;
    11)
      http-server -a 127.0.0.1 -p 8090
      am start -a android.intent.action.VIEW -d http://127.0.0.1:8090
      ;;
    12)
      start_biliup
      mkdir .biliup && cd .biliup && biliup start
      am start -a android.intent.action.VIEW -d http://127.0.0.1:3000
      ;;
    13)
      am start -a android.intent.action.VIEW -d http://127.0.0.1:8083
      ;;
    14)
      start_obs
      ;;
    15)
      start_gif
      ;;
    16)
      start_thumbnails
      ;;
    *) break ;;
    esac
  done
}
while true; do
  echo -e "${GREEN_COLOR}1.install${RES}"
  echo -e "${GREEN_COLOR}2.start${RES}"
  read choice
  case $choice in
  1) time install ;;
  2) time start ;;
  *) break ;;
  esac
done
cheetsheet_nvim() {
  echo -e "${GREEN_COLOR}1.astronvim${RES}"
  echo -e "${GREEN_COLOR}2.lazyvim${RES}"
  echo -e "${GREEN_COLOR}3.lunarvim${RES}"
  echo -e "${GREEN_COLOR}4.nvchad${RES}"
  read choice
  case $choice in
  1)
    if [ ! -d ~/.config/nvim.lunarvim ]; then
      mv ~/.config/nvim ~/.config/nvim.lunarvim
      mv ~/.config/nvim.astronvim ~/.config/nvim
      echo "lunarvim backuped"
      nvim
    elif [ ! -d ~/.config/nvim.lazyvim ]; then
      mv ~/.config/nvim ~/.config/nvim.lazyvim
      mv ~/.config/nvim.astronvim ~/.config/nvim
      echo lazyvim backuped
      nvim
    elif [ ! -d ~/.config/nvim.nvchad ]; then
      mv ~/.config/nvim ~/.config/nvim.nvchad
      mv ~/.config/nvim.astronvim ~/.config/nvim
      echo "nvchad backuped"
      nvim
    fi
    ;;
  2)
    if [ ! -d "~/.config/nvim.nvchad" ]; then
      mv ~/.config/nvim ~/.config/nvim.nvchad
      mv ~/.config/nvim.lazyvim ~/.config/nvim
      echo "nvchad backuped"
      nvim
    elif [ ! -d "~/.config/nvim.lunarvim" ]; then
      mv ~/.config/nvim ~/.config/nvim.lunarvim
      mv ~/.config/nvim.lazyvim ~/.config/nvim
      echo "lunarvim backuped"
      nvim
    elif [ ! -d "~/.config/nvim.astronvim" ]; then
      mv ~/.config/nvim ~/.config/nvim.astronvim
      mv ~/.config/nvim.lazyvim ~/.config/nvim
      echo "astronvim backuped"
      nvim
    fi
    ;;
  3)
    if [ ! -d "~/.config/nvim.nvchad" ]; then
      mv ~/.config/nvim ~/.config/nvim.nvchad
      mv ~/.config/nvim.lunarvim ~/.config/nvim
      echo "nvchad backuped"
      nvim
    elif [ ! -d "~/.config/nvim.lazyvim" ]; then
      mv ~/.config/nvim ~/.config/nvim.lazyvim
      mv ~/.config/nvim.lunarvim ~/.config/nvim
      echo "lazyvim backuped"
      nvim
    elif [ ! -d "~/.config/nvim.astronvim" ]; then
      mv ~/.config/nvim ~/.config/nvim.astronvim
      mv ~/.config/nvim.lunarvim ~/.config/nvim
      echo "astronvim backuped"
      nvim
    fi
    ;;
  4)
    if [ ! -d "~/.config/nvim.lunarvim" ]; then
      mv ~/.config/nvim ~/.config/nvim.lunarvim
      mv ~/.config/nvim.nvchad ~/.config/nvim
      echo "lunarvim backuped"
      nvim
    elif [ ! -d "~/.config/nvim.lazyvim" ]; then
      mv ~/.config/nvim ~/.config/nvim.lazyvim
      mv ~/.config/nvim.nvchad ~/.config/nvim
      echo "lazyvim backuped"
      nvim
    elif [ ! -d "~/.config/nvim.astronvim" ]; then
      mv ~/.config/nvim ~/.config/nvim.astronvim
      mv ~/.config/nvim.nvchad ~/.config/nvim
      echo "astronvim backuped"
      nvim
    fi
    ;;
  *) break ;;
  esac
}
#cheetsheet_tmux() {
#  cat <<EOF >"~/.tmux.conf"
#  set -g status off
#  bind-key -n C-a send-prefix
#  EOF
#}
cheetsheet_termux() {
  termux-battery-status
  termux-camera-info
  termux-contact-list
  termux-infrared-frequencies
  termux-telephony-cellinfo
  termux-telephony-deviceinfo
  termux-tts-engines
  termux-wifi-connectioninfo
  termux-wifi-scaninfo
  termux-brightness auto
  termux-camera-photo -c 0 termux-camera-photo.jpg
  rm -rf termux-camera-photo.jpg
  termux-clipboard-set PHP是世界上最好的语言
  termux-clipboard-get
  termux-infrared-transmit -f 20,50,20,30
  termux-location -p network
  termux-microphone-record -d -f 1.m4a
  termux-microphone-record -q
  rm 1.m4a
  termux-notification -t '国光的Termu通知测试' -c 'Hello Termux' --type default
  termux-toast -b white -c black Hello Termux
  termux-torch on
  termux-torch off
  termux-tts-speak 'Hello world!'
  termux-vibrate -f -d 3000
  termux-wallpaper -l -f
  termux-wifi-enable false
  termux-wifi-enable true
  termux-dialog confirm -i 'Hello Termux' -t 'confirm测试'
  termux-dialog checkbox -v 'Overwatch,GTA5,LOL' -t '平时喜欢玩啥游戏'
  termux-dialog date -d 'yyyy-MM-dd' -t '你的出生日期是?'
  termux-dialog radio -v '小哥哥,小姐姐' -t '你的性别是?'
  termux-dialog sheet -v '菜鸡,国光'
  termux-dialog spinner -v '国光,光光' -t '你最喜欢的博主是?'
  termux-dialog text -i '密码:' -t '请输入核弹爆炸密码'
  termux-dialog time -t '你每天多少点睡觉?'
}
