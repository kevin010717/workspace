#!/bin/bash
#set -x
#chmod +x "$0"

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
	sudo apt update && sudo apt install bpytop gnome-shell-extension-manager cmus screen docker.io docker-compose rustup curl neovim git gh zsh net-tools tmux openssh-server build-essential npm fzf ytfzf ranger rtv tree neofetch htop kitty calibre pandoc fuse3 python3 python3-venv python3-pip pipx samba -y
	pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple	
  #rustup update stable && rustup show && rustup default 
	cargo install --locked --git https://github.com/sxyazi/yazi.git yazi-fm yazi-cli #yazi
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
		ssh-keygen -t rsa -b 4096 -C “k511153362gmail.com” && cat ~/.ssh/id_rsa.pub && read -p "更新github ssh keys" key && ssh -T git@github.com
		git config --global user.email "k511153362@gmail.com" && git config --global user.name "kevin010717" && gh auth login
		;;
	esac

	read -p "VirtManager?(y/n):" choice
	case $choice in
	y)
    #VirtManager
   sudo grep -E -c '(vmx|svm)' /proc/cpuinfo
   sudo apt install cpu-checker && kvm-ok
   sudo apt update
   sudo apt install qemu-system libguestfs-tools libvirt-clients libvirt-daemon-system bridge-utils virt-manager ovmf swtpm
   sudo usermod -a -G libvirt $USER
   sudo usermod -a -G kvm $USER
   sudo usermod -a -G input $USER
   sudo systemctl enable libvirtd
   sudo systemctl start libvirtd
   sudo virsh net-start default
   sudo virsh net-autostart default
   #spice
   sudo apt install spice-vdagent qemu-guest-agent
   sudo systemctl enable --now spice-vdagent
   sudo systemctl enable --now qemu-guest-agent
   #iommu
   sudo sed -i 's|^GRUB_CMDLINE_LINUX_DEFAULT=".*"|GRUB_CMDLINE_LINUX_DEFAULT="quiet splash intel_iommu=on iommu=pt"|' /etc/default/grub
   sudo update-grub
   sudo reboot
   #ban nvgpu
   #sudo apt purge nvidia-driver-535
   #sudo apt install xserver-xorg-video-nouveau
   #band gpu with vfio
   sudo mv /lib/udev/rules.d/71-nvidia.rules /lib/udev/rules.d/71-nvidia.rules.bak
   sudo systemctl disable nvidia-persistenced
   sudo lspci -nnk
   echo "vfio vfio_iommu_type1 vfio_virqfd vfio_pci ids=10de:28a1,10de:22be" | sudo tee -a /etc/initramfs-tools/modules
   echo "options vfio-pci ids=10de:28a1,10de:22be" | sudo tee -a /etc/modprobe.d/vfio.conf
   #discrete gpu
   sudo bash -c 'cat <<EOF >>/etc/modprobe.d/nvidia.conf
   softdep nouveau pre: vfio-pci
   softdep nvidia pre: vfio-pci
   softdep nvidia* pre: vfio-pci
EOF'
   echo "options kvm ignore_msrs=1" | sudo tee -a /etc/modprobe.d/kvm.conf
   sudo update-initramfs -u -k all
   sudo update-grub
   sudo reboot
   sudo lspci -nnk
   #looking glass
   sudo apt install looking-glass-client
   #<devices>
   #  <shmem name='looking-glass'>
   #    <model type='ivshmem-plain'/>
   #    <size unit='M'>32</size>
   #  </shmem>
   #</devices>
   echo "f /dev/shm/looking-glass 0660 kevin kvm - " | sudo tee -a /etc/tmpfiles.d/10-looking-glass.conf
   sudo systemd-tmpfiles --create /etc/tmpfiles.d/10-looking-glass.conf
   #win11安装virtio-win-gt-x64.msi VC_redist.x64.exe Looking Glass Client vdd
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
alias h="htop"
alias sc="source ~/.zshrc"
alias ip="ifconfig | lolcat"
alias map="telnet mapscii.me"
alias vmwin='if sudo virsh domstate win11 | grep -q "shut off"; then \
    sudo nohup virsh start win11 >/dev/null 2>&1; \
fi && \
echo "f /dev/shm/looking-glass 0660 kevin kvm - " | sudo tee -a /etc/tmpfiles.d/10-looking-glass.conf && \
sudo systemd-tmpfiles --create /etc/tmpfiles.d/10-looking-glass.conf && \
nohup looking-glass-client -F egl:vsync >/dev/null 2>&1 &'
alias vmubuntu='if sudo virsh domstate ubuntu24.04 | grep -q "shut off"; then sudo nohup virsh start ubuntu24.04 >/dev/null 2>&1; fi && sudo nohup virt-viewer -f -w ubuntu24.04 >/dev/null 2>&1 &'
alias vmshutdown="sudo virsh list --name | xargs -r -I {} sudo virsh shutdown {} "
alias vmpoweroff="sudo virsh list --name | xargs -r -I {} sudo virsh destroy {} "
alias vmlist="sudo virsh list --all"
alias vmubuntusnapshot="sudo virsh snapshot-create-as ubuntu24.04 --name snapshot_name --description "快照描述""
alias vmwinsnapshot="sudo virsh snapshot-create-as win11 --name snapshot_name --description "快照描述""
date
curl -s 'wttr.in/{shanghai,fujin}?format=4'
EOF
    source ~/.zshrc
		#合盖不休眠
		sudo sed -i 's/#HandleLidSwitch=suspend/HandleLidSwitch=ignore/' /etc/systemd/logind.conf
		sudo sed -i 's/#HandleLidSwitchExternalPower=suspend/HandleLidSwitchExternalPower=ignore/' /etc/systemd/logind.conf
		#sudo 无密码
		echo '%kevin     ALL=(ALL) NOPASSWD: ALL' | sudo tee -a /etc/sudoers
		#docker
		sudo systemctl start docker && sudo systemctl enable docker
    #chrome
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && sudo apt install -y ./google-chrome-stable_current_amd64.deb && rm google-chrome-stable_current_amd64.deb
    #clash
    wget https://github.com/clash-verge-rev/clash-verge-rev/releases/download/dependencies/libwebkit2gtk-4.0-37_2.43.3-1_amd64.deb https://github.com/clash-verge-rev/clash-verge-rev/releases/download/dependencies/libjavascriptcoregtk-4.0-18_2.43.3-1_amd64.deb https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v1.7.7/clash-verge_1.7.7_amd64.deb
    sudo apt install ./libwebkit2gtk-4.0-37_2.43.3-1_amd64.deb ./libjavascriptcoregtk-4.0-18_2.43.3-1_amd64.deb ./clash-verge_1.7.7_amd64.deb
    #font
    mkdir -p ~/.local/share/fonts && cp ~/.workspace/.config/0xProtoNerdFont-Regular.ttf ~/.local/share/fonts/ && fc-cache -fv
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
