#!/bin/bash
#set -x
chmod +x "$0"

RED_COLOR='\e[1;31m'
GREEN_COLOR='\e[1;32m'
YELLOW_COLOR='\e[1;33m'
BLUE_COLOR='\e[1;34m'
PINK_COLOR='\e[1;35m'
SHAN='\e[1;33;5m'
RES='\e[0m'

#
#
#todo
#迁移到服务器
#换键盘布局
#translate.nvim termdebug.vim vimspector vimwiki editor-outline
#
#
install-linuxbrew() {
  sudo apt update
  sudo apt install build-essential curl file git
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  (
    echo
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
  ) >>/home/kevin/.zshrc
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  source "/home/kevin/.zshrc"
  brew --version
}

install-samba() {
  sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.bak
  cat >>/etc/samba/smb.conf <<EOF
  [sambashare]
  comment = Samba on ubuntu
  path = /
  read only = no
  browsable = yes
EOF
  sudo smbpasswd -a kevin
  sudo service smbd restart
  sudo systemctl restart smbd
  sudo systemctl enable smbd
}
install-filebrowser() {
  curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
  sudo nohup filebrowser -a 0.0.0.0 -p 18650 -r / -d ~/.filebrowser/filebrowser.db --disable-type-detection-by-header --disable-preview-resize --disable-exec --disable-thumbnails --cache-dir ~/.filebrowser/cache >/dev/null 2>&1 &
}
install-cd2() {
  sudo -i
  mount --make-shared /
  mkdir -p /CloudNAS /Config /media
  docker pull cloudnas/clouddrive2:latest
  docker run -d \
    --name clouddrive \
    --restart unless-stopped \
    --env CLOUDDRIVE_HOME=/Config \
    -v /CloudNAS:/CloudNAS:shared \
    -v /Config:/Config \
    -v /media:/media:shared \
    --network host \
    --pid host \
    --privileged \
    --device /dev/fuse:/dev/fuse \
    cloudnas/clouddrive2:latest
}
install-git() {
  git config --global user.email "k511153362@gmail.com"
  git config --global user.name "kevin010717"
  gh auth login
  gh repo clone kevin010717/ubuntu-install

  ssh-keygen -t rsa -b 4096 -C “k511153362gmail.com”
  cat ~/.ssh/id_rsa.pub
  ssh -T git@github.com
}

install-zeretier-one() {
  curl -s https://install.zerotier.com | sudo bash
  sudo systemctl start zerotier-one
  sudo chmod a+w /usr/lib/systemd/system/zerotier-one.service
  sudo sed -i '/^After.*/s/$/ shellcrash.service/' /usr/lib/systemd/system/zerotier-one.service
  sudo systemctl daemon-reload
  sudo zerotier-cli join 8056c2e21c28950a
}

install-gitbook() {
  sudo npm install -g bun gitbook-cli n
  sudo n 10.22.0
  sudo n run 10.22.0 /usr/local/bin/gitbook --version
}
install-docker() {
  sudo apt-get install docker.io
  sudo systemctl start docker
  sudo systemctl enable docker
  echo '{
  "registry-mirrors": [
  "https://2h3poj2z.mirror.aliyuncs.com"
  ]
}' | sudo tee /etc/docker/daemon.json >/dev/null
  sudo docker run hello-world
  sudo curl -L "https://github.com/docker/compose/releases/download/v2.27.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  docker-compose --version
}

install-calibre-web() {
  mkdir "$HOME/calibre-web"
  mkdir "$HOME/calibre-web/books/"
  mkdir "$HOME/calibre-web/config/"
  sudo chmod 777 -R "$HOME/calibre-web/"
  sudo docker run -d \
    --name=calibre-web \
    -e PUID=1000 \
    -e PGID=1000 \
    -e TZ=Etc/UTC \
    -e DOCKER_MODS=linuxserver/mods:universal-calibre `#optional` \
    -e OAUTHLIB_RELAX_TOKEN_SCOPE=1 `#optional` \
    -p 8083:8083 \
    -v "$HOME/calibre-web/config:/config" \
    -v "$HOME/calibre-web/books:/books" \
    --restart unless-stopped \
    linuxserver/calibre-web:latest
}

install-chatgpt-next-web() {
  sudo docker pull yidadaa/chatgpt-next-web
  sudo docker run -d -p 3000:3000 \
    -e OPENAI_API_KEY=sk-pfQvDlLpDDVSlj1I618e034d18Fc4bBd866392F612F3Bb8f \
    -e CODE=6666 \
    -e BASE_URL=https://oneapi.xty.app \
    --restart always \
    yidadaa/chatgpt-next-web
  #sk-wlm6Xs71oEJ379JE1027B83bEeFa4dF493Dc82Cb4e7dB170 https://apikeyplus.com
}

install-ubuntu-setup() {
  #合盖不休眠
  sudo sed -i 's/#HandleLidSwitch=suspend/HandleLidSwitch=ignore/' /etc/systemd/logind.conf
  sudo sed -i 's/#HandleLidSwitchExternalPower=suspend/HandleLidSwitchExternalPower=ignore/' /etc/systemd/logind.conf
  #sudo systemctl restart systemd-logind.service
  #sudo 无密码
  echo '%kevin     ALL=(ALL) NOPASSWD: ALL' | sudo tee -a /etc/sudoers
  #google-chrome
  wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  sudo dpkg -i google-chrome-stable_current_amd64.deb
  google-chrome
}

install-alacritty() {
  sudo apt install cmake pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev python3
  sudo apt install alacritty
}

install-config() {
  sh -c "$(curl -fsSL https://install.ohmyz.sh/)" #ohmyzsh

  git clone https://github.com/LazyVim/starter ~/.config/nvim #lazyvim

  pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple #pip源

  sudo cp /etc/apt/sources.list.d/ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources.bak #ubuntu源
  echo "Enabled: yes
Types: deb
URIs: http://mirrors.tuna.tsinghua.edu.cn/ubuntu/
Suites: noble noble-updates noble-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg" | sudo tee /etc/apt/sources.list.d/ubuntu.sources

  cat <<EOF >>/etc/profile
cvt 2560 1440
xrandr --newmode "2560x1440_60.00" 312.25 2560 2752 3024 3488 1440 1443 1448 1493 -hsync +vsync
xrandr --addmode Virtual-1 "2560x1440_60.00"
EOF

  cat <<EOF >>~/.zshrc && source ~/.zshrc
neofetch
#rxfetch
if [ -f ~/termux-install/todo.md ]; then
  glow ~/termux-install/todo.md
fi
alias s="slides ~/termux-install/dairy.md"
alias g="glow ~/termux-install/todo.md"
alias n="nvim"
alias y="yazi"
alias c='screen -q -r -D cmus || screen -S cmus $(which --skip-alias cmus)'
#shell screen -d cmus
alias gacp="git add . ; git commit -m "1" ;git push origin main"
EOF

}

install-update() {
  sudo apt update
  sudo apt install curl neovim git gh zsh net-tools tmux openssh-server build-essential npm fzf ytfzf ranger rtv cargo tree neofetch htop kitty calibre pandoc fuse3 python3 python3-venv python3-pip pipx samba -y
  sudo apt install cmus screen -y
  sudo snap install slides glow lazygit
  rustup update stable && rustup show && rustup default
  cargo install --locked --git https://github.com/sxyazi/yazi.git yazi-fm yazi-cli #yazi
  echo "export PATH="$HOME/.cargo/bin:$PATH"" >>~/.zshrc
  #pipx install tomato-clock
  #pipx run --spec tomato-clock tomato
  #npm install -g percollate #web pages to epub
}

install-shellcrash() {
  sudo -i
  bash
  export url='https://fastly.jsdelivr.net/gh/juewuy/ShellCrash@master' && wget -q --no-check-certificate -O /tmp/install.sh $url/install.sh && bash /tmp/install.sh && source /etc/profile &>/dev/null
}

install() {
  while true; do
    echo -e "${GREEN_COLOR}1.shellcrash${RES}"
    echo -e "${GREEN_COLOR}2.update${RES}"
    echo -e "${GREEN_COLOR}3.config${RES}"
    echo -e "${GREEN_COLOR}4.alacritty${RES}"
    echo -e "${GREEN_COLOR}5.ubuntu-setup${RES}"
    echo -e "${GREEN_COLOR}6.docker${RES}"
    echo -e "${GREEN_COLOR}7.chatgpt-next-web${RES}"
    echo -e "${GREEN_COLOR}8.calibre-web${RES}"
    echo -e "${GREEN_COLOR}9.gitbook${RES}"
    echo -e "${GREEN_COLOR}10.zeretier-one${RES}"
    echo -e "${GREEN_COLOR}11.git${RES}"
    read -r choice
    case $choice in
    1) install-shellcrash ;;
    2) install-update ;;
    3) install-config ;;
    4) install-alacritty ;;
    5) install-ubuntu-setup ;;
    6) install-docker ;;
    7) install-chatgpt-next-web ;;
    8) install-calibre-web ;;
    9) install-gitbook ;;
    10) install-zeretier-one ;;
    11) install-git ;;
    *) break ;;
    esac
  done
}

start-gitbook() {
  sudo gitbook init
  sudo gitbook epub
  sudo gitbook pdf
  sudo gitbook mobi
  sudo gitbook build
}
start() {
  while true; do
    echo -e "${GREEN_COLOR}1.gitbook${RES}"
    read -r choice
    case $choice in
    1) start-gitbook ;;
    *) break ;;
    esac
  done
}

while true; do
  echo -e "${GREEN_COLOR}1.install${RES}"
  echo -e "${GREEN_COLOR}2.start${RES}"
  read -r choice
  case $choice in
  1) install ;;
  2) start ;;
  *) break ;;
  esac
done
