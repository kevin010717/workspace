#!/data/data/com.termux/files/usr/bin/bash

# 双击长按事件
# 截图事件
# 屏幕触摸功能切换

# 监听全部输入设备，避免音量上 / 音量下不在同一个 event 里导致无法触发
GETEVENT_CMD="/system/bin/getevent -lt"

MOONLIGHT_PKG="com.limelight.qiin"

# 防抖时间，避免长按或重复 DOWN 连续触发
COOLDOWN=1
LAST_TRIGGER=0

launch_moonlight() {
  su -c "input keyevent WAKEUP"
  su -c "sh -c 'pm enable $MOONLIGHT_PKG >/dev/null 2>&1 && monkey -p $MOONLIGHT_PKG -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1'"
}

do_nothing() {
  :
}

handle_key() {
  KEY="$1"

  NOW="$(date +%s)"
  if [ $((NOW - LAST_TRIGGER)) -lt "$COOLDOWN" ]; then
    return
  fi
  LAST_TRIGGER="$NOW"

  case "$KEY" in
  VOLUMEUP)
    # 音量上键触发动作
    do_nothing
    launch_moonlight
    ;;

  VOLUMEDOWN)
    # 音量下键触发动作
    do_nothing
    launch_moonlight
    ;;

  ASSISTANT)
    # Xperia 数字助理键 01c9
    do_nothing
    launch_moonlight
    ;;

  CAMERA_FOCUS)
    # 半按相机对焦键，KEY_CAMERA_FOCUS / 02fe
    do_nothing
    launch_moonlight
    ;;

  CAMERA_02FE)
    # 02fe 数字形式
    do_nothing
    # launch_moonlight
    ;;
  esac
}

echo "开始监听 Xperia 实体按键..."
echo "音量上: KEY_VOLUMEUP"
echo "音量下: KEY_VOLUMEDOWN"
echo "数字助理键: 01c9"
echo "相机对焦键: KEY_CAMERA_FOCUS / 02fe"
echo ""

su -c "$GETEVENT_CMD" | while IFS= read -r line; do
  case "$line" in
  *EV_KEY*KEY_VOLUMEUP*DOWN*)
    handle_key "VOLUMEUP"
    ;;

  *EV_KEY*KEY_VOLUMEDOWN*DOWN*)
    handle_key "VOLUMEDOWN"
    ;;

  *EV_KEY*01c9*DOWN*)
    handle_key "ASSISTANT"
    ;;

  *EV_KEY*KEY_CAMERA_FOCUS*DOWN*)
    handle_key "CAMERA_FOCUS"
    ;;

  *EV_KEY*02fe*DOWN*)
    handle_key "CAMERA_02FE"
    ;;
  esac
done
