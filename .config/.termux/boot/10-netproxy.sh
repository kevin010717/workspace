#!/data/data/com.termux/files/usr/bin/sh

# NetProxy 开机自动配置脚本
# 日志位置：~/netproxy-boot.log

# termux-wake-lock
# sleep 30
LOG="$HOME/.netproxy-boot.log"

CLI='/data/adb/modules/netproxy/scripts/cli'
URL='https://30e9533d6d5c2e91c98c9b9e31cd9086.alicdn.sbs/alicdn.com/1729753854'
SUB_NAME='yep'
NODE_NAME='Auto-Fastest'

echo "========== $(date) ==========" >>"$LOG"

run_root() {
  echo "+ su -c \"$*\"" >>"$LOG"
  su -c "$*" >>"$LOG" 2>&1
  echo "exit=$?" >>"$LOG"
  echo >>"$LOG"
}

# 等待 Magisk 模块文件就绪，最多 30 秒
i=0
while [ ! -x "$CLI" ] && [ "$i" -lt 30 ]; do
  sleep 1
  i=$((i + 1))
done

if [ ! -x "$CLI" ]; then
  echo "ERROR: cli not found or not executable: $CLI" >>"$LOG"
  echo "DONE with error: $(date)" >>"$LOG"
  echo >>"$LOG"
  exit 1
fi

# 原来的 8 条命令，保留顺序
run_root "$CLI service stop"
run_root "$CLI sub add $SUB_NAME '$URL'"
run_root "$CLI sub update-all"
run_root "$CLI node use $NODE_NAME"
run_root "$CLI service restart"
run_root "$CLI mode rule"
run_root "$CLI api groups"
run_root "$CLI node list"

# . "$PREFIX/etc/profile.d/start-services.sh"
# sv-enable sshd
# sv up sshd
# sv status sshd

echo "DONE: $(date)" >>"$LOG"
echo >>"$LOG"
