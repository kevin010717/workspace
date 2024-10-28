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
  sudo apt remove snapd
	sudo apt update && sudo apt install wmctrl bpytop gnome-shell-extension-manager cmus screen docker.io docker-compose rustup curl neovim git gh zsh net-tools tmux openssh-server sshfs build-essential npm fzf ytfzf ranger rtv tree neofetch htop kitty calibre pandoc fuse3 python3 python3-venv python3-pip pipx samba -y
	pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple	
  rustup update stable && rustup show && rustup default && cargo install --locked --git https://github.com/sxyazi/yazi.git yazi-fm yazi-cli #yazi
  cargo install tlrc
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
sudo nano /etc/apt/sources.list
   sudo update-grub
   sudo reboot
   sudo lspci -nnk
   #looking glass
   sudo apt install looking-glass-client
   #win11安装virtio-win-gt-x64.msi VC_redist.x64.exe Looking Glass Client vdd
   #<devices>
   #  <shmem name='looking-glass'>
   #    <model type='ivshmem-plain'/>
   #    <size unit='M'>32</size>
   #  </shmem>
   #</devices>
   #Hugepage
   sudo bash -c 'cat <<EOF >> /etc/sysctl.d/99-sysctl.conf
   vm.nr_hugepages=4096
   vm.hugetlb_shm_group=48
EOF'
   #wadroid
   sudo apt install curl ca-certificates lzip python3 python3-pip
   curl https://repo.waydro.id | sudo bash
   sudo apt install waydroid
   sudo bash -c 'cat <<EOF >>/etc/apt/sources.list
   deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal main restricted universe multiverse
   deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-updates main restricted universe multiverse
   deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-backports main restricted universe multiverse
   deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-security main restricted universe multiverse
EOF'
   sudo waydroid init -s GAPPS -f
   sudo systemctl start waydroid-container
   sudo systemctl enable waydroid-container
sudo waydroid shell
#ANDROID_RUNTIME_ROOT=/apex/com.android.runtime ANDROID_DATA=/data ANDROID_TZDATA_ROOT=/apex/com.android.tzdata ANDROID_I18N_ROOT=/apex/com.android.i18n sqlite3 /data/data/com.google.android.gsf/databases/gservices.db "select * from main where name = \"android_id\";"
	read -p "https://www.google.com/android/uncertified注册设备" choice
sudo apt install lzip
git clone https://github.com/casualsnek/waydroid_script ~/.waydroid_script
cd ~/.waydroid_script
python3 -m venv venv
venv/bin/pip install -r requirements.txt
sudo venv/bin/python3 main.py 
		;;
	esac

	read -p "filebrowser?(y/n):" choice
	case $choice in
	y)
		curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
		sudo nohup filebrowser -a 0.0.0.0 -p 18650 -r / -d ~/.filebrowser/filebrowser.db --disable-type-detection-by-header --disable-preview-resize --disable-exec --disable-thumbnails --cache-dir ~/.filebrowser/cache >/dev/null 2>&1 &
		;;
	esac

	read -p "filebrowser?(y/n):" choice
	case $choice in
	y)
    wget https://github.com/LizardByte/Sunshine/releases/latest/download/sunshine-ubuntu-24.04-amd64.deb
    sudo apt install ~/sunshine-ubuntu-24.04-amd64.deb

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

  read -p "docker?(y/n):" choice
  case $choice in
    y)
      # 更新包列表
      sudo apt update
      # 安装必要的依赖包
      sudo apt install apt-transport-https ca-certificates curl software-properties-common
      # 添加 Docker 的官方 GPG 密钥
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
      # 添加 Docker APT 仓库
      sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
      # 更新包列表
      sudo apt update
      # 安装 Docker
      sudo apt install docker-ce
      # 启动 Docker 服务
      sudo systemctl start docker
      # 设置 Docker 开机自启
      sudo systemctl enable docker
      # 验证安装
      sudo docker --version
      # （可选）将当前用户添加到 Docker 用户组
      sudo usermod -aG docker $USER
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
if tmux has-session 2>/dev/null; then tmux attach; else tmux; fi
export PATH="$HOME/.cargo/bin:$PATH"
neofetch
#rxfetch
alias s="slides ~/termux-install/dairy.md"
alias g="glow ~/termux-install/todo.md"
alias n="nvim"
alias y="yazi"
alias c='screen -q -r -D cmus || screen -S cmus $(which --skip-alias cmus)'#shell screen -d cmus
alias gacp="git add . ; git commit -m "1" ;git push origin main"
alias h="bpytop"
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
sudo systemctl start waydroid-container
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
    sudo mkdir -p ~/.local/share/fonts && sudo cp ~/.workspace/.config/0xProtoNerdFont-Regular.ttf ~/.local/share/fonts/ && fc-cache -fv
    #autostart
    cp -rf ~/.workspace/.config/autostart/ ~/.config/
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

createubuntu(){
qemu-system-x86_64 \
-machine q35 \
-drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.secboot.fd \
-drive if=pflash,format=raw,file=OVMF_VARS_4M.fd \
-accel kvm \
-cpu host \
-smp sockets=1,cores=4,threads=1 \
-m 4096 \
-netdev user,id=n1 -device virtio-net,netdev=n1 \
-vga std \
-display gtk \
-device intel-hda \
-usbdevice tablet \
-boot menu=on \
-drive file=ubuntu.qcow2,if=virtio,format=qcow2 \
#-cdrom ubuntu-24.04-desktop-amd64.iso

: << 'EOF'
这是一个多行注释，用于解释以下 QEMU 命令的配置。
1. -machine q35: 使用 Q35 机器类型。
2. -cpu host-passthrough: 直接使用主机的 CPU 特性。
3. -m 8192: 分配 8GB 的内存。
4. -smp 6: 设置 6 个虚拟 CPU。
5. -accel kvm: 启用 KVM 加速。
6. -bios: 指定 OVMF 固件文件。
7. -drive: 硬盘配置，使用 Virtio 设备。
8. -device: 网络、视频和音频设备配置。
9. -boot menu=on: 启用启动菜单。
10. -nographic: 如果不需要图形输出，可以启用此选项。
11. -display spice: 使用 SPICE 显示。
12. -memballoon: 启用内存气球设备。
13. -rng: 使用随机数生成器设备。

qemu-system-x86_64 \
  -machine q35 \
  -cpu host-passthrough \
  -m 8192 \
  -smp 6 \
  -accel kvm \
  -bios /usr/share/OVMF/OVMF_CODE_4M.secboot.fd \
  -drive file=/var/lib/libvirt/images/ubuntu24.04.qcow2,if=virtio,format=qcow2 \
  -device virtio-net,netdev=n1 \
  -netdev user,id=n1 \
  -device qxl,ram=65536,vram=65536,vgamem=16384,heads=1,primary=yes \
  -device ich9-intel-hda \
  -device usb-tablet \
  -boot menu=on \
  -nographic \
  -display spice \
  -soundhw ich9 \
  -memballoon virtio \
  -rng virtio,backend=model=random,filename=/dev/urandom \
  -drive file=/usr/share/OVMF/OVMF_VARS_4M.fd,if=pflash \
  -enable-kvm
EOF
}

exportwin(){
mkdir win11 
sudo virsh dumpxml win11 > ~/win11/win11.xml  
sudo cp /var/lib/libvirt/images/win11.qcow2 ~/win11/win11.qcow2
sudo cp /var/lib/libvirt/qemu/nvram/win11_VARS.fd ~/win11/win11_VARS.fd
sudo cp /usr/share/OVMF/OVMF_CODE_4M.secboot.fd ~/win11/OVMF_CODE_4M.secboot.fd

cp ~/win11/win11.qcow2 /var/lib/libvirt/images/win11.qcow2
cp ~/win11/win_VARS.fd /var/lib/libvirt/qemu/nvram/win11_VARS.fd
virsh define --file ~/win11/windows11.xml
}
