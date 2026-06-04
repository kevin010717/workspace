su -c 'settings get secure icon_blacklist'
su -c "settings delete secure icon_blacklist"
su -c 'settings put system status_bar_show_battery_percent 1'
su -c 'cmd statusbar get-status-icons'
# 隐藏状态栏图标，包含左上角clock
su -c "sh -c '
settings get secure icon_blacklist > /sdcard/icon_blacklist.bak

icons=\$(cmd statusbar get-status-icons 2>/dev/null \
  | sed \"s/[][]//g\" \
  | tr \", \" \"\n\" \
  | sed \"/^$/d\" \
  | sort -u \
  | paste -sd, -)

[ -z \"\$icons\" ] && icons=\"mobile,volte,airplane,location,wifi,nfc,vpn,bluetooth,volume,zen,alarm_clock,headset,ime,battery,rotate,cast,su\"

case \",\$icons,\" in
  *,clock,*) ;;
  *) icons=\"\$icons,clock\" ;;
esac

settings put secure icon_blacklist \"\$icons\"
pkill -f com.android.systemui
'"
# 隐藏状态栏 没啥用
su -c "sh -c 'settings put global policy_control immersive.status=*; pkill -f com.android.systemui'"
