#!/data/data/com.termux/files/usr/bin/bash
#set -x
chmod +x "$0"

#todo
#markdown-web
#gitbook
#chatgpt
#termux-api
#zerotier
#termux代理软件：v2ray singbox mihomo(clash.meta) dae crashshell 目前用magisk模块
#nnn.vim
#nnn filebrowser
#kali

update() {
  #pkg i docker -y
  #ssh-keygen -t rsa && ssh-copy-id -i ~/.ssh/id_rsa.pub kevin@10.147.17.140
  #cargo install clock-tui bk
  #pip install epr-reader
  #tidal-dl
  #pkg install python clang libjpeg-turbo ffmpeg zlib -y
  #pip3 install --upgrade tidal-dl
  #mytermux.git
  #go install github.com/aandrew-me/tgpt/v2@latest && cp ~/go/bin/tgpt $PREFIX/bin/tgpt
  #go install github.com/TheZoraiz/ascii-image-converter@latest && cp ~/go/bin/ascii-image-converter $PREFIX/bin/ascii-image-converter && rm -rf ~/go/
  #git clone https://github.com/fcambus/ansiweather.git ~/.ansiweather
  #git clone https://github.com/YashBansod/Robotics-Planning-Dynamics-and-Control.git ~/.Robotics-Planning-Dynamics-and-Control
  #git clone https://github.com/LinuxDroidMaster/Termux-Desktops.git ~/.Termux-Desktops
  #git clone --depth=1 https://github.com/adi1090x/polybar-themes.git ~/.config/polybar-themes && chmod +x ~/.config/polybar-themes/setup.sh && ~/.config/polybar-themes/setup.sh
  #git clone --depth=1 https://github.com/Gorkido/termux-desktop-i3.git && cd termux-desktop-i3 && chmod +x setup.sh && ./setup.sh --install
  #git clone --depth=1 https://github.com/adi1090x/termux-desktop.git && cd termux-desktop && chmod +x setup.sh && ./setup.sh --install
  #git clone https://github.com/ruanyf/fortunes.git ~/.fortunes && cp ~/.fortunes/data/* $PREFIX/share/games/fortunes/
  read -p "update?(y/n):" choice
  case $choice in
    y)
      termux-setup-storage
      termux-change-repo
      pkg update && pkg upgrade -y
      pkg i root-repo x11-repo tur-repo -y
      pkg i termux-services termux-api tsu -y
      pkg i busybox openssh sshfs rsync cronie wget ffmpeg mpv iptables samba man iperf3 ripgrep whiptail -y
      sudo iptables -A INPUT -p tcp --dport 6080 -j ACCEPT # for termux
      pkg i rust golang android-tools python-pip nodejs xmake -y
      pkg i speedtest-go fastfetch rxfetch cpufetch neofetch nethogs htop screen tmux zsh gh git gitui lazygit git-delta cloneit neovim slides glow -y
      pkg i hollywood no-more-secrets peaclock tty-clock cmatrix nyancat coreutils figlet toilet weechat fortune cowsay sl w3m greed moon-buggy -y
      pkg i ncmpcpp mpd cmus mpg123 tizonia -y
      pkg i nnn ranger yazi mc lsd eza zoxide fzf gdu dust tree -y
      pkg i termimage imagemagick jq bc bk lux atuin chezmoi -y
      pkg install termux-x11-nightly xfce gimp proot-distro pulseaudio virglrenderer-android -y #x11
      pkg install i3 rofi picom feh kitty alacritty polybar pavucontrol flameshot alsa-utils -y #i3
      su -c "/system/bin/device_config set_sync_disabled_for_tests persistent; /system/bin/device_config put activity_manager max_phantom_processes 2147483647" # fix signal 9 problem
      cargo install tlrc mcfly
      pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple && pip install youtube-dl yt-dlp you-get PySocks lolcat bpython tldr
      npm config set registry https://registry.npmmirror.com && npm i docsify-cli mapscii cordova -g
      echo "type openssh passwd:" && passwd && sv-enable sshd
      sh -c "$(curl -fsSL https://install.ohmyz.sh/)"
      git clone https://github.com/LazyVim/starter ~/.config/nvim && nvim
      git clone https://github.com/kevin010717/workspace.git ~/.workspace 
      cp -rf ~/.workspace/.config/ ~/ 
      cp -f ~/.workspace/.config/.termux/termux.properties ~/.termux/termux.properties && termux-reload-settings
      cp -f ~/.workspace/.zshrc ~/.zshrc
      ;;
  esac

  read -p "prootubuntu?(y/n):" choice
  case $choice in
    y)
      proot-distro install ubuntu
      proot-distro login ubuntu --user root --shared-tmp --termux-home -- bash -c "sh /data/data/com.termux/files/home/.workspace/script/prootubuntu.sh"
      proot-distro login ubuntu --user user --shared-tmp --termux-home -- bash -c "sh /data/data/com.termux/files/home/.workspace/script/prootubuntu.sh"
      ;;
  esac

  read -p "git config?(y/n):" choice
  case $choice in
    y)
      ssh-keygen -t rsa -b 4096 -C “k511153362gmail.com” && cat ~/.ssh/id_rsa.pub
      am start -a android.intent.action.VIEW -d https://github.com && read -p "更新github ssh keys" key && ssh -T git@github.com
      git config --global user.email "k511153362@gmail.com"
      git config --global user.name "kevin010717"
      gh auth login
      ;;
  esac

  read -p "clouddrive?(y/n):" choice
  case $choice in
    y)
      #curl -fsSL "https://mirror.ghproxy.com/https://github.com/kevin010717/clouddrive2/blob/main/cd2-termux.sh" | bash -s install root mirror
      /data/data/com.termux/files/home/.workspace/script/cd2/cd2-termux.sh install root 
      cat <<EOF >>~/.zshrc
      if ! pgrep -f "clouddrive" > /dev/null; then
        sudo nohup nsenter -t 1 -m -- /bin/bash -c "cd /data/data/com.termux/files/home/.clouddrive/ && sudo ./clouddrive" >/dev/null 2>&1 &
      fi
EOF
      source ~/.zshrc
      am start -a android.intent.action.VIEW -d http://127.0.0.1:19798/
      ;;
  esac

  read -p "filebrowser?(y/n):" choice
  case $choice in
    y)
      mkdir .filebrowser
      wget -O .filebrowser/filebrowser.tar.gz https://github.com/filebrowser/filebrowser/releases/download/v2.29.0/linux-arm64-filebrowser.tar.gz
      tar -zxvf .filebrowser/filebrowser.tar.gz -C .filebrowser
      chmod +x .filebrowser/filebrowser
      cat <<EOF >>~/.zshrc
      if ! pgrep -f "filebrowser" > /dev/null; then
        sudo nohup ~/.filebrowser/filebrowser -a 0.0.0.0 -p 18650 -r /data/data/com.termux/files -d ~/.filebrowser/filebrowser.db --disable-type-detection-by-header --disable-preview-resize --disable-exec --disable-thumbnails --cache-dir ~/.filebrowser/cache >/dev/null 2>&1 &
      fi
EOF
      source ~/.zshrc
      am start -a android.intent.action.VIEW -d http://127.0.0.1:18650
      ;;
  esac

  read -p "samba?(y/n):" choice
  case $choice in
    y)
      sudo iptables -t nat -A PREROUTING -p tcp --dport 445 -j REDIRECT --to-port 4445
      sudo iptables -t nat -A OUTPUT -p tcp --dport 445 -j REDIRECT --to-port 4445
      mkdir $PREFIX/etc/samba
      sed 's#@TERMUX_HOME@/storage/shared#/data/data/com.termux/files/home#g' $PREFIX/share/doc/samba/smb.conf.example >$PREFIX/etc/samba/smb.conf
      echo "type samba passwd:" && pdbedit -a -u admin
      cat <<EOF >>~/.zshrc
      if ! pgrep -f "smbd" > /dev/null; then
        smbd
      fi
EOF
      source ~/.zshrc
      smbclient -p 445 //127.0.0.1/internal -U admin
      ;;
  esac

  read -p "calibreweb?(y/n):" choice
  case $choice in
    y)
      pip install tzdata
      pkg i libxml2 libxslt -y
      pip install --user -U calibreweb
      cat <<EOF >>~/.zshrc
      if ! pgrep -f "calibreweb" > /dev/null; then
        nohup python ~/.local/lib/python3.12/site-packages/calibreweb/__main__.py >/dev/null 2>&1 &
      fi
EOF
      source ~/.zshrc
      am start -a android.intent.action.VIEW -d http://127.0.0.1:8083
      ;;
  esac

  read -p "aria2?(y/n):" choice
  case $choice in
    y)
      pkg install aria2
      pkg install git nodejs
      git clone https://github.com/ziahamza/webui-aria2.git
      mv webui-aria2 .webui-aria2
      cat <<EOF >>~/.zshrc
      if ! pgrep -f "aria2" > /dev/null; then
        cd .webui-aria2
        sudo nohup aria2c --enable-rpc --rpc-listen-all >/dev/null 2>&1 &
        sudo nohup node node-server.js >/dev/null 2>&1 &
        cd ~
      fi
EOF
      source ~/.zshrc
      am start -a android.intent.action.VIEW -d http://127.0.0.1:8888
      echo "访问https://github.com/ngosang/trackerslist添加tracker"
      ;;
  esac

  read -p "qbittorrent?(y/n):" choice
  case $choice in
    y)
      wget https://github.com/userdocs/qbittorrent-nox-static/releases/download/release-4.5.2_v2.0.8/aarch64-qbittorrent-nox
      mv aarch64-qbittorrent-nox /data/data/com.termux/files/usr/bin/qbittorrent
      chmod +x /data/data/com.termux/files/usr/bin/qbittorrent
      cat <<EOF >>~/.zshrc
      if ! pgrep -f "qbittorrent" > /dev/null; then
        sudo nohup qbittorrent --webui-port=8088 >/dev/null 2>&1 &
      fi
EOF
      source ~/.zshrc
      am start -a android.intent.action.VIEW -d http://127.0.0.1:8088
      ;;
  esac

  read -p "chfs?(y/n):" choice
  case $choice in
    y)
      wget --no-check-certificate https://iscute.cn/tar/chfs/3.1/chfs-linux-arm64-3.1.zip
      unzip chfs-linux-arm64-3.1.zip
      chmod +x chfs-linux-arm64-3.1
      mv chfs-linux-arm64-3.1 /data/data/com.termux/files/usr/bin/chfs
      rm chfs-linux-arm64-3.1.zip
      cat <<EOF >>~/.zshrc
      if ! pgrep -f "chfs" > /dev/null; then
        nohup sudo chfs --port=1234 >/dev/null 2>&1 &
      fi
EOF
      source ~/.zshrc
      am start -a android.intent.action.VIEW -d http://127.0.0.1:1234
      ;;
  esac

  read -p "http-server?(y/n):" choice
  case $choice in
    y)
      pkg install nodejs
      npm install -g http-server
      cat <<EOF >>~/.zshrc
      if ! pgrep -f "http-server" > /dev/null; then
        sudo nohup http-server -a 127.0.0.1 -p 8090 >/dev/null 2>&1 &
      fi
EOF
      source ~/.zshrc
      am start -a android.intent.action.VIEW -d http://127.0.0.1:8090
      ;;
  esac

  read -p "code-server?(y/n):" choice
  case $choice in
    y)
      apt install tur-repo                          #安装软件源
      apt install code-server                       #安装
      cat ~/.suroot/.config/code-server/config.yaml #查看密码
      cat <<EOF >>~/.zshrc
      if ! pgrep -f "code-server" > /dev/null; then
        sudo nohup code-server >/dev/null 2>&1 &
      fi
EOF
      source ~/.zshrc
      am start -a android.intent.action.VIEW -d http://127.0.0.1:8080
      ;;
  esac

  read -p "nodeserver?(y/n):" choice
  case $choice in
    y)
      mkdir .nodeserver && cd .nodeserver && npm init && npm install express --save
      cat <<EOF >>server.js
      const express = require('express');
      const app = express();
      app.get('/', (req, res) => {
      res.send('Hello World!');
    });
    app.listen(3000, () => {
    console.log('Server is running at http://localhost:3000');
  });
EOF
  cat <<EOF >>~/.zshrc
  sudo nohup node server.js >/dev/null 2>&1 &
  EOF
  source ~/.zshrc
  am start -a android.intent.action.VIEW -d http://127.0.0.1:3000
  ;;
esac

read -p "tmoe?(y/n):" choice
case $choice in
  y)
    curl -LO l.tmoe.me/tinor.deb
    apt install ./tinor.deb
    apt update
    bash -c "$(curl -L l.tmoe.me)"
    ;;
esac

read -p "biliup?(y/n):" choice
case $choice in
  y)
    mkdir builds
    cd builds/
    git clone https://github.com/saghul/pycares
    pip install setuptools
    python setup.py install
    cd ~
    rm -r builds -y

    pip install --user -U streamlink biliup
    echo “export PATH="${HOME}/.local/bin:${PATH}"” >.bashrc && source .bashrc && echo $PATH
    mkdir .biliup && cd .biliup && biliup start
    am start -a android.intent.action.VIEW -d http://127.0.0.1:3000
    ;;
esac

read -p "leetcode-cli?(y/n):" choice
case $choice in
  y)
    npm install -g leetcode-cli
    cargo install leetcode-cli
    ;;
esac

read -p "chrootubuntu?(y/n):" choice
case $choice in
  y)
    #chroot-ubuntu 需要magisk-busybox
    mkdir chrootubuntu && cd chrootubuntu
    wget https://cdimage.ubuntu.com/ubuntu-base/releases/22.04/release/ubuntu-base-22.04-base-arm64.tar.gz
    tar xpvf ubuntu-base-22.04-base-arm64.tar.gz --numeric-owner && sudo mkdir sdcard && sudo mkdir dev/shm
    cd ~ && ~/.workspace/script/chrootubuntu.sh
    ;;
esac
}

obs() {
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

gif() {
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

thumbnails() {
  # 遍历当前目录下的所有 .mp4 和 .mkv 文件
  for video_file in *.mp4 *.mkv; do
    # 忽略非文件类型的东西（如目录）
    [[ -f "$video_file" ]] || continue

    local thumbnail_file="${video_file%.*}.png" # 生成缩略图文件名
    echo "正在处理视频文件：$video_file"

    # 使用 ffmpeg 生成缩略图
    sudo ffmpeg -hide_banner -loglevel panic -y \
      -i "$video_file" \
      -frames 1 \
      -vf "thumbnail,scale=1080:-1,tile=1X5:padding=10:color=white" \
      "$thumbnail_file"
  done
}

chrootubuntu(){
killall -9 termux-x11 Xwayland pulseaudio virgl_test_server_android termux-wake-lock
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity
sudo busybox mount --bind $PREFIX/tmp $HOME/chrootubuntu/tmp
XDG_RUNTIME_DIR=${TMPDIR} termux-x11 :0 -ac &
sleep 3
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1
pacmd load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1
virgl_test_server_android &
export UBUNTUPATH='/data/data/com.termux/files/home/chrootubuntu'
su -c "
# Ubuntu檔案系統所在路徑
export UBUNTUPATH='/data/data/com.termux/files/home/chrootubuntu'

# 解決setuid問題
busybox mount -o remount,dev,suid /data

busybox mount --bind /dev $UBUNTUPATH/dev
busybox mount --bind /sys $UBUNTUPATH/sys
busybox mount --bind /proc $UBUNTUPATH/proc
busybox mount -t devpts devpts $UBUNTUPATH/dev/pts

# Electron APPS需要/dev/shm
busybox mount -t tmpfs -o size=256M tmpfs $UBUNTUPATH/dev/shm

# 掛載內部儲存空間
busybox mount --bind /sdcard $UBUNTUPATH/sdcard

# chroot至Ubuntu
#busybox chroot $UBUNTUPATH /bin/su - root
#busybox chroot $UBUNTUPATH /bin/su - user -c 'export DISPLAY=:0 PULSE_SERVER=tcp:127.0.0.1:4713 && dbus-launch --exit-with-session startplasma-x11'
busybox chroot $UBUNTUPATH /bin/su - user -c 'export DISPLAY=:0 PULSE_SERVER=tcp:127.0.0.1:4713 && dbus-launch --exit-with-session startxfce4'

# 退出shell後取消掛載，因為後面要裝圖形環境所以這裡是註解狀態。若沒有要裝圖形環境再將以下指令取消註解。
busybox umount $UBUNTUPATH/dev/shm
busybox umount $UBUNTUPATH/dev/pts
busybox umount $UBUNTUPATH/dev
busybox umount $UBUNTUPATH/proc
busybox umount $UBUNTUPATH/sys
busybox umount $UBUNTUPATH/sdcard
"
}

prootubuntu(){
    killall -9 termux-x11 Xwayland pulseaudio virgl_test_server_android termux-wake-lock
    am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity
    XDG_RUNTIME_DIR=${TMPDIR}
    termux-x11 :0 -ac &
    sleep 3
    pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1
    pacmd load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1
    virgl_test_server_android &
    #MESA_NO_ERROR=1 MESA_GL_VERSION_OVERRIDE=4.3COMPAT MESA_GLES_VERSION_OVERRIDE=3.2 GALLIUM_DRIVER=zink ZINK_DESCRIPTORS=lazy virgl_test_server --use-egl-surfaceless --use-gles &
    #MESA_LOADER_DRIVER_OVERRIDE=zink GALLIUM_DRIVER=zink ZINK_DESCRIPTORS=lazy virgl_test_server --use-egl-surfaceless --use-gles &
    proot-distro login ubuntu --user user --shared-tmp --termux-home -- bash -c "export DISPLAY=:0 PULSE_SERVER=tcp:127.0.0.1; dbus-launch --exit-with-session i3" # i3 startxfce4
}

nativetermux(){
    killall -9 termux-x11 Xwayland pulseaudio virgl_test_server_android termux-wake-lock
    am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity
    XDG_RUNTIME_DIR=${TMPDIR}
    termux-x11 :0 -ac &
    sleep 3
    pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1
    pacmd load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1
    virgl_test_server_android &
    termux-x11 :0 -xstartup "dbus-launch --exit-with-session i3"
    #termux-x11 :0 -xstartup "dbus-launch --exit-with-session xfce4-session"
    #termux-x11 :0 -xstartup "dbus-launch --exit-with-session openbox-session"
}

case "$1" in
  update)
    time update;;
  obs)
    time obs;;
  gif)
    time gif;;
  thumbnails)
    time thumbnails;;
  nativetermux)
    time nativetermux;;
  prootubuntu)
    time prootubuntu;;
  chrootubuntu)
    time chrootubuntu;;
  *)
    # 如果没有有效参数，则显示菜单
    while true; do
      echo -e "1. update"
      echo -e "2. obs"
      echo -e "3. gif"
      echo -e "4. thumbnails"
      echo -e "5. nativetermux"
      echo -e "6. prootubuntu"
      echo -e "7. chrootubuntu-start"
      read -p "请选择一个选项 (或输入其他内容以退出): " choice
      
      case $choice in
        1) time update ;;
        2) time obs ;;
        3) time gif ;;
        4) time thumbnails ;;
        5) time termuxx11-start ;;
        6) time prootubuntu  ;;
        7) time chrootubuntu ;;
        *) echo "退出。" && break ;;
      esac
    done
    ;;
esac

cheetsheet_nvim() {
  echo -e "1.astronvim"
  echo -e "2.lazyvim"
  echo -e "3.lunarvim"
  echo -e "4.nvchad"
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
