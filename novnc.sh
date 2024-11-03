#VNC

#noVNC
sudo git clone https://github.com/novnc/noVNC.git $PREFIX/bin/noVNC
iptables -A INPUT -p tcp --dport 6080 -j ACCEPT # for termux
sudo ufw allow 6080/tcp # for linnux
$PREFIX/bin/noVNC/utils/novnc_proxy --vnc localhost:5901 --listen 6080
