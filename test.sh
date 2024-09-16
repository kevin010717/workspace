#!/bin/bash

cat <<EOF >>~/.config/yazi/yazi.toml
[opener]
browser = [
	{ run = 'am start -a android.intent.action.VIEW -d "http://127.0.0.1:18650${1#*/com.termux}" && echo $1 ', orphan = true, for = "unix" },
	{ run = 'mpv --force-window %*', orphan = true, for = "windows" },
	{ run = '''mediainfo "$1"; echo "Press enter to exit"; read _''', block = true, desc = "Show media info", for = "unix" },
] 

[open]
rules = [
	# Media
  #{ mime = "{audio,video}/*", use = [ "play", "reveal" ] },
	{ mime = "{audio,video}/*", use = [ "browser" ] },
]
EOF
