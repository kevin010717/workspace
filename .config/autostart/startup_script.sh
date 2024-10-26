#!/bin/bash

# 等待一段时间确保系统启动完成
sleep 2

# 打开第一个全屏终端
gnome-terminal --full-screen &

# 等待一段时间以确保终端完全打开
sleep 1

# 切换到第二个桌面
wmctrl -s 1

# 打开第二个全屏终端并启动 Chrome
#google-chrome-stable & sleep 2; wmctrl -r :ACTIVE: -b toggle,fullscreen
google-chrome-stable

