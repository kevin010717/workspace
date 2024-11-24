#!/bin/bash

#sunshine 
sleep 1
nohup sunshine>/dev/null 2>&1 &

#terminal 
sleep 1
gnome-terminal --full-screen &
#switch workspace
sleep 1
wmctrl -s 1

#Chrome
sleep 1
nohup google-chrome-stable >/dev/null 2>&1 &
#switch workspace
#sleep 1
#wmctrl -s 3

#virt-manager
#sleep 1
#nohup virt-manager >/dev/null 2>&1 &
#switch workspace
#sleep 1
#wmctrl -s 4

#wadroid
#sleep 1
#nohup waydroid show-full-ui >/dev/null 2>&1 &
