#!/bin/sh

# 中止所有舊行程
killall -9 termux-x11 Xwayland pulseaudio virgl_test_server_android termux-wake-lock

## 啟動Termux X11
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity

sudo busybox mount --bind $PREFIX/tmp $HOME/chrootubuntu/tmp

XDG_RUNTIME_DIR=${TMPDIR} termux-x11 :0 -ac &

sleep 3

# 啟動Termux的Pulse Audio
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1
pacmd load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1

# 啟動virgl server
virgl_test_server_android &

# 執行chroot Ubuntu的指令稿
#su -c "sh /data/data/com.termux/files/home/chrootubuntu-hook.sh"

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
#busybox chroot $UBUNTUPATH /bin/su - root -c 'export DISPLAY=:0 PULSE_SERVER=tcp:127.0.0.1:4713 && dbus-launch --exit-with-session startxfce4'
busybox chroot $UBUNTUPATH /bin/su - root -c 'export DISPLAY=:0 PULSE_SERVER=tcp:127.0.0.1:4713 && dbus-launch --exit-with-session startplasma-x11'

# 退出shell後取消掛載，因為後面要裝圖形環境所以這裡是註解狀態。若沒有要裝圖形環境再將以下指令取消註解。
busybox umount $UBUNTUPATH/dev/shm
busybox umount $UBUNTUPATH/dev/pts
busybox umount $UBUNTUPATH/dev
busybox umount $UBUNTUPATH/proc
busybox umount $UBUNTUPATH/sys
busybox umount $UBUNTUPATH/sdcard
"
