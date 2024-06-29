#!/data/data/com.termux/files/usr/bin/bash
termux-battery-status
termux-camera-info
termux-contact-list
termux-infrared-frequencies
termux-telephony-cellinfo
termux-telephony-deviceinfo
termux-tts-engines
termux-wifi-connectioninfo
termux-wifi-scaninfo
termux-brightness auto
termux-camera-photo -c 0 termux-camera-photo.jpg
rm -rf termux-camera-photo.jpg
termux-clipboard-set PHP是世界上最好的语言
termux-clipboard-get
termux-infrared-transmit -f 20,50,20,30
termux-location -p network
termux-microphone-record -d -f 1.m4a
termux-microphone-record -q 
rm 1.m4a
termux-notification -t '国光的Termu通知测试' -c 'Hello Termux' --type default
termux-toast -b white -c black Hello Termux
termux-torch on 
termux-torch off
termux-tts-speak 'Hello world!'
termux-vibrate -f -d 3000
termux-wallpaper -l -f 
termux-wifi-enable false
termux-wifi-enable true

termux-dialog confirm -i 'Hello Termux' -t 'confirm测试'

termux-dialog checkbox -v 'Overwatch,GTA5,LOL' -t '平时喜欢玩啥游戏'

termux-dialog date -d 'yyyy-MM-dd' -t '你的出生日期是?'

termux-dialog radio -v '小哥哥,小姐姐' -t '你的性别是?'

termux-dialog sheet -v '菜鸡,国光'

termux-dialog spinner -v '国光,光光' -t '你最喜欢的博主是?'

termux-dialog text -i '密码:' -t '请输入核弹爆炸密码'

termux-dialog time -t '你每天多少点睡觉?'


