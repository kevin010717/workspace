# 密钥目录 /data/ssh/root/.ssh/authorized_keys /data/ssh/shell/.ssh/authorized_keys
ssh-keygen -t ed25519 -f $env:USERPROFILE\.ssh\android_magisk_ed25519
chmod 700 /data/ssh/root/.ssh
chmod 600 /data/ssh/root/.ssh/authorized_keys
chown -R root:root /data/ssh/root/.ssh
chmod 700 /data/ssh/shell/.ssh
chmod 600 /data/ssh/shell/.ssh/authorized_keys
chown -R shell:shell /data/ssh/shell/.ssh
# windows连接
ssh -i $env:USERPROFILE\.ssh\android_magisk_ed25519 root@192.168.1.62
