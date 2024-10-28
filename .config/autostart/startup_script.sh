#!/bin/bash

#terminal 
sleep 1
gnome-terminal --full-screen &

#switch workspace
sleep 1
wmctrl -s 1

#Chrome
sleep 1
nohup google-chrome-stable >/dev/null 2>&1 &

#waydroid 
#sleep 1
#nohup waydroid show-full-ui >/dev/null 2>&1 &

#sunshine 
sleep 1
nohup sunshine>/dev/null 2>&1 &
