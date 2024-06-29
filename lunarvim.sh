
#!/bin/bash

if [ ! -d "~/.config/nvim.nvchad" ]; then
	mv ~/.config/nvim ~/.config/nvim.nvchad
  mv ~/.config/nvim.lunarvim ~/.config/nvim
	echo "nvchad backuped"
  nvim
else if [ ! -d "~/.config/nvim.lazyvim" ]; then
	mv ~/.config/nvim ~/.config/nvim.lazyvim
  mv ~/.config/nvim.lunarvim ~/.config/nvim
	echo "lazyvim backuped"
  nvim
else if [ ! -d "~/.config/nvim.astronvim" ]; then
	mv ~/.config/nvim ~/.config/nvim.astronvim
  mv ~/.config/nvim.lunarvim ~/.config/nvim
	echo "astronvim backuped"
  nvim
fi

