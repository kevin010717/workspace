#!/system/bin/sh

MOD="/data/adb/modules/xperia_moonlight_keys"

echo "正在安装 Xperia Moonlight Hardware Keys 模块..."

# 必须 root 执行
if [ "$(id -u)" != "0" ]; then
  echo "错误：请先执行 su 进入 root，再运行本脚本。"
  exit 1
fi

# 删除旧模块目录，重新创建
rm -rf "$MOD"
mkdir -p "$MOD/scripts"

# Magisk 模块信息
cat >"$MOD/module.prop" <<'EOF'
id=xperia_moonlight_keys
name=Xperia Moonlight Hardware Keys
version=1.3-safe
versionCode=4
author=termux
description=Launch Moonlight with Xperia hardware keys safely
EOF

# Magisk 开机后执行的服务脚本
cat >"$MOD/service.sh" <<'EOF'
#!/system/bin/sh

MODDIR=${0%/*}

LOG_FILE="/data/local/tmp/xperia-keys-moonlight-service.log"
SCRIPT="$MODDIR/scripts/xperia-keys-moonlight.sh"
PID_FILE="/data/local/tmp/xperia-keys-moonlight.pid"
DISABLE_FLAG="/data/local/tmp/xperia_moonlight_keys.disable"

SCRIPT_NAME="xperia-keys-moonlight.sh"
MAX_BOOT_WAIT=120

log_msg() {
    echo "[$(date '+%F %T')] $*" >> "$LOG_FILE"
}

rotate_log() {
    if [ -f "$LOG_FILE" ]; then
        SIZE="$(wc -c < "$LOG_FILE" 2>/dev/null | tr -d ' ')"

        if [ -n "$SIZE" ] && [ "$SIZE" -gt 1048576 ] 2>/dev/null; then
            mv "$LOG_FILE" "$LOG_FILE.1" 2>/dev/null
        fi
    fi
}

is_our_script_running() {
    OLD_PID="$1"

    [ -n "$OLD_PID" ] || return 1
    [ -d "/proc/$OLD_PID" ] || return 1

    CMDLINE="$(tr '\0' ' ' < "/proc/$OLD_PID/cmdline" 2>/dev/null)"

    case "$CMDLINE" in
        *"$SCRIPT_NAME"*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

rotate_log
log_msg "service.sh started"

# 临时禁用开关
if [ -f "$DISABLE_FLAG" ]; then
    log_msg "disable flag exists, service skipped"
    exit 0
fi

# Magisk 模块禁用开关
if [ -f "$MODDIR/disable" ]; then
    log_msg "Magisk module disable file exists, service skipped"
    exit 0
fi

# 检查主脚本是否存在
if [ ! -f "$SCRIPT" ]; then
    log_msg "watcher script not found: $SCRIPT"
    exit 1
fi

# 等待系统启动完成，最多等待 120 秒
BOOT_WAIT=0

while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
    BOOT_WAIT=$((BOOT_WAIT + 2))

    if [ "$BOOT_WAIT" -ge "$MAX_BOOT_WAIT" ]; then
        log_msg "boot_completed timeout after ${MAX_BOOT_WAIT}s, exit"
        exit 0
    fi
done

sleep 5

# 启动前再次检查禁用开关
if [ -f "$DISABLE_FLAG" ] || [ -f "$MODDIR/disable" ]; then
    log_msg "disable flag found after boot, service skipped"
    exit 0
fi

# 防止重复启动
if [ -f "$PID_FILE" ]; then
    OLD_PID="$(cat "$PID_FILE" 2>/dev/null)"

    if is_our_script_running "$OLD_PID"; then
        log_msg "watcher already running, pid=$OLD_PID, skip start"
        exit 0
    fi

    log_msg "stale pid file found, remove it"
    rm -f "$PID_FILE"
fi

nohup /system/bin/sh "$SCRIPT" >> "$LOG_FILE" 2>&1 &

NEW_PID=$!
echo "$NEW_PID" > "$PID_FILE"

sleep 1

if is_our_script_running "$NEW_PID"; then
    log_msg "watcher started successfully, pid=$NEW_PID"
else
    log_msg "watcher may have failed to start, pid=$NEW_PID"
    rm -f "$PID_FILE"
fi
EOF

# 主监听脚本
cat >"$MOD/scripts/xperia-keys-moonlight.sh" <<'EOF'
#!/system/bin/sh

GETEVENT_CMD="/system/bin/getevent -lt"

# Moonlight 包名
MOONLIGHT_PKG="com.limelight.qiin"

# 是否启用音量键触发
# 1 = 启用
# 0 = 禁用
ENABLE_VOLUME_KEYS=1

COOLDOWN=1
LAST_TRIGGER=0

LOG_FILE="/data/local/tmp/xperia-keys-moonlight.log"
PID_FILE="/data/local/tmp/xperia-keys-moonlight.pid"
DISABLE_FLAG="/data/local/tmp/xperia_moonlight_keys.disable"

SCRIPT_NAME="xperia-keys-moonlight.sh"
CLEANED=0

log_msg() {
    echo "[$(date '+%F %T')] $*" >> "$LOG_FILE"
}

rotate_log() {
    if [ -f "$LOG_FILE" ]; then
        SIZE="$(wc -c < "$LOG_FILE" 2>/dev/null | tr -d ' ')"

        if [ -n "$SIZE" ] && [ "$SIZE" -gt 1048576 ] 2>/dev/null; then
            mv "$LOG_FILE" "$LOG_FILE.1" 2>/dev/null
        fi
    fi
}

is_our_script_running() {
    OLD_PID="$1"

    [ -n "$OLD_PID" ] || return 1
    [ -d "/proc/$OLD_PID" ] || return 1

    CMDLINE="$(tr '\0' ' ' < "/proc/$OLD_PID/cmdline" 2>/dev/null)"

    case "$CMDLINE" in
        *"$SCRIPT_NAME"*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

startup_lock() {
    if [ -f "$PID_FILE" ]; then
        OLD_PID="$(cat "$PID_FILE" 2>/dev/null)"

        if [ "$OLD_PID" != "$$" ] && is_our_script_running "$OLD_PID"; then
            log_msg "another watcher is already running, pid=$OLD_PID, exit"
            exit 0
        fi
    fi

    echo "$$" > "$PID_FILE"
}

cleanup() {
    if [ "$CLEANED" = "1" ]; then
        return
    fi

    CLEANED=1

    OLD_PID="$(cat "$PID_FILE" 2>/dev/null)"

    if [ "$OLD_PID" = "$$" ]; then
        rm -f "$PID_FILE"
    fi

    log_msg "watcher stopped"
}

trap cleanup 0
trap 'cleanup; exit 0' 2 15

launch_moonlight() {
    log_msg "launch Moonlight requested"

    if [ -f "$DISABLE_FLAG" ]; then
        log_msg "disable flag exists, launch skipped"
        return
    fi

    if ! pm path "$MOONLIGHT_PKG" >/dev/null 2>&1; then
        log_msg "Moonlight package not found: $MOONLIGHT_PKG"
        return
    fi

    input keyevent WAKEUP >/dev/null 2>&1
    pm enable "$MOONLIGHT_PKG" >/dev/null 2>&1
    monkey -p "$MOONLIGHT_PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1

    if [ "$?" -eq 0 ]; then
        log_msg "Moonlight launch command sent"
    else
        log_msg "Moonlight launch failed"
    fi
}

handle_key() {
    KEY="$1"

    if [ -f "$DISABLE_FLAG" ]; then
        return
    fi

    NOW="$(date +%s)"

    if [ $((NOW - LAST_TRIGGER)) -lt "$COOLDOWN" ]; then
        return
    fi

    LAST_TRIGGER="$NOW"

    case "$KEY" in
        VOLUMEUP)
            if [ "$ENABLE_VOLUME_KEYS" = "1" ]; then
                log_msg "KEY_VOLUMEUP triggered"
                # launch_moonlight
            else
                log_msg "KEY_VOLUMEUP ignored"
            fi
            ;;

        VOLUMEDOWN)
            if [ "$ENABLE_VOLUME_KEYS" = "1" ]; then
                log_msg "KEY_VOLUMEDOWN triggered"
                # launch_moonlight
            else
                log_msg "KEY_VOLUMEDOWN ignored"
            fi
            ;;

        ASSISTANT)
            log_msg "assistant key triggered"
            # launch_moonlight
            ;;

        CAMERA_FOCUS)
            log_msg "KEY_CAMERA_FOCUS triggered"
            launch_moonlight
            ;;

        CAMERA_02FE)
            log_msg "02fe key triggered, ignored"
            ;;
    esac
}

rotate_log

if [ -f "$DISABLE_FLAG" ]; then
    log_msg "disable flag exists, watcher exit"
    exit 0
fi

startup_lock

log_msg "xperia-keys-moonlight watcher started, pid=$$"

if [ ! -x /system/bin/getevent ]; then
    log_msg "/system/bin/getevent not found or not executable"
    exit 1
fi

$GETEVENT_CMD 2>>"$LOG_FILE" | while IFS= read -r line; do
    case "$line" in
        *EV_KEY*KEY_VOLUMEUP*DOWN*)
            handle_key "VOLUMEUP"
            ;;

        *EV_KEY*KEY_VOLUMEDOWN*DOWN*)
            handle_key "VOLUMEDOWN"
            ;;

        *EV_KEY*KEY_ASSISTANT*DOWN*|*EV_KEY*01c9*DOWN*|*EV_KEY*000001c9*DOWN*)
            handle_key "ASSISTANT"
            ;;

        *EV_KEY*KEY_CAMERA_FOCUS*DOWN*)
            handle_key "CAMERA_FOCUS"
            ;;

        *EV_KEY*02fe*DOWN*|*EV_KEY*000002fe*DOWN*)
            handle_key "CAMERA_02FE"
            ;;
    esac
done
EOF

# 设置权限
chmod 755 "$MOD"
chmod 644 "$MOD/module.prop"
chmod 755 "$MOD/service.sh"
chmod 755 "$MOD/scripts"
chmod 755 "$MOD/scripts/xperia-keys-moonlight.sh"

echo ""
echo "安装完成。"
echo ""

echo "====== 直接检查安装文件 ======"
ls -ld "$MOD"
ls -l "$MOD"
ls -ld "$MOD/scripts"
ls -l "$MOD/scripts"

echo ""
echo "====== 日志位置 ======"
echo "服务日志：/data/local/tmp/xperia-keys-moonlight-service.log"
echo "按键日志：/data/local/tmp/xperia-keys-moonlight.log"

echo ""
echo "====== 正常启用 ======"
echo "确认上面的 ls -l 结果没问题后，手动执行："
echo "reboot"

echo ""
echo "====== 临时禁用监听脚本，不删除模块 ======"
echo "如果还能进系统，执行："
echo "su"
echo "touch /data/local/tmp/xperia_moonlight_keys.disable"
echo "reboot"

echo ""
echo "====== 恢复启用监听脚本 ======"
echo "su"
echo "rm -f /data/local/tmp/xperia_moonlight_keys.disable"
echo "reboot"

echo ""
echo "====== 禁用整个 Magisk 模块 ======"
echo "su"
echo "touch /data/adb/modules/xperia_moonlight_keys/disable"
echo "reboot"

echo ""
echo "====== 删除整个模块 ======"
echo "su"
echo "rm -rf /data/adb/modules/xperia_moonlight_keys"
echo "rm -f /data/local/tmp/xperia-keys-moonlight.pid"
echo "rm -f /data/local/tmp/xperia_moonlight_keys.disable"
echo "reboot"

echo ""
echo "====== 如果开机循环，Recovery / TWRP / adb shell 救急 ======"
echo "进入 recovery 的 adb shell 后执行："
echo "rm -rf /data/adb/modules/xperia_moonlight_keys"
echo "rm -f /data/local/tmp/xperia-keys-moonlight.pid"
echo "rm -f /data/local/tmp/xperia_moonlight_keys.disable"
echo "reboot"

echo ""
echo "====== 安全提醒 ======"
echo "本脚本不会自动 reboot。"
echo "请确认 ls -l 输出正常后，再手动 reboot。"
echo "第一次测试如果担心误触发，可以把："
echo "$MOD/scripts/xperia-keys-moonlight.sh"
echo "里面的 ENABLE_VOLUME_KEYS=1 改成 ENABLE_VOLUME_KEYS=0。"
