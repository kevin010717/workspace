#!/bin/bash
#set -x
chmod +x "$0"

#
#
#todo
#迁移到服务器
#换键盘布局
#translate.nvim termdebug.vim vimspector vimwiki editor-outline
#
#

update() {
	#sudo add-apt-repository "deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $(lsb_release -cs) main restricted universe multiverse"
	#sudo add-apt-repository "deb https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
	sudo apt update && sudo apt install cmus screen docker.io docker-compose rustup curl neovim git gh zsh net-tools tmux openssh-server build-essential npm fzf ytfzf ranger rtv cargo tree neofetch htop kitty calibre pandoc fuse3 python3 python3-venv python3-pip pipx samba -y
	pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple	
 	rustup update stable && rustup show && rustup default && cargo install --locked --git https://github.com/sxyazi/yazi.git yazi-fm yazi-cli #yazi
	sh -c "$(curl -fsSL https://install.ohmyz.sh/)"
	git clone https://github.com/LazyVim/starter ~/.config/nvim
	git clone https://github.com/kevin010717/workspace.git ~/.workspace
	#sudo snap install slides glow lazygit
	#npm install -g percollate #web pages to epub
	#pipx install tomato-clock
	#pipx run --spec tomato-clock tomato

	read -p "git config?(y/n):" choice
	case $choice in
	y)
		ssh-keygen -t rsa -b 4096 -C “k511153362gmail.com” && cat ~/.ssh/id_rsa.pub
		read -p "更新github ssh keys" key && ssh -T git@github.com
		git config --global user.email "k511153362@gmail.com"
		git config --global user.name "kevin010717"
		gh auth login
		;;
	esac

	read -p "filebrowser?(y/n):" choice
	case $choice in
	y)
		curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
		sudo nohup filebrowser -a 0.0.0.0 -p 18650 -r / -d ~/.filebrowser/filebrowser.db --disable-type-detection-by-header --disable-preview-resize --disable-exec --disable-thumbnails --cache-dir ~/.filebrowser/cache >/dev/null 2>&1 &
		;;
	esac

	read -p "samba?(y/n):" choice
	case $choice in
	y)
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
		sudo systemctl restart smbd && sudo systemctl enable smbd
		;;
	esac

	read -p "docker clouddrive2?(y/n):" choice
	case $choice in
	y)
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
		;;
	esac

	read -p "docker chatgpt-next-web?(y/n):" choice
	case $choice in
	y)
		sudo docker pull yidadaa/chatgpt-next-web
		sudo docker run -d -p 3000:3000 \
			-e OPENAI_API_KEY=sk-pfQvDlLpDDVSlj1I618e034d18Fc4bBd866392F612F3Bb8f \
			-e CODE=6666 \
			-e BASE_URL=https://oneapi.xty.app \
			--restart always \
			yidadaa/chatgpt-next-web
		#sk-wlm6Xs71oEJ379JE1027B83bEeFa4dF493Dc82Cb4e7dB170 https://apikeyplus.com
		;;
	esac

	read -p "git config?(y/n):" choice
	case $choice in
	y)
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
		;;
	esac

	read -p "config?(y/n):" choice
	case $choice in
	y)
		cat <<EOF >>~/.zshrc && source ~/.zshrc
export PATH="$HOME/.cargo/bin:$PATH"
neofetch
#rxfetch
alias s="slides ~/termux-install/dairy.md"
alias g="glow ~/termux-install/todo.md"
alias n="nvim"
alias y="yazi"
alias c='screen -q -r -D cmus || screen -S cmus $(which --skip-alias cmus)'#shell screen -d cmus
alias gacp="git add . ; git commit -m "1" ;git push origin main"
cal
date
EOF
		#合盖不休眠
		sudo sed -i 's/#HandleLidSwitch=suspend/HandleLidSwitch=ignore/' /etc/systemd/logind.conf
		sudo sed -i 's/#HandleLidSwitchExternalPower=suspend/HandleLidSwitchExternalPower=ignore/' /etc/systemd/logind.conf
		#sudo 无密码
		echo '%kevin     ALL=(ALL) NOPASSWD: ALL' | sudo tee -a /etc/sudoers
		#docker
		sudo systemctl start docker && sudo systemctl enable docker
		;;
	esac
}

while true; do
	echo -e "1.update"
	read -r choice
	case $choice in
	1) update ;;
	*) break ;;
	esac
done
