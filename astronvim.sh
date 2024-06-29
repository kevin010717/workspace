#!/bin/bash

if [ ! -d "~/.config/nvim.lunarvim" ]; then
	mv ~/.config/nvim ~/.config/nvim.lunarvim
  mv ~/.config/nvim.astronvim ~/.config/nvim
	echo "lunarvim backuped"
  nvim
else if [ ! -d "~/.config/nvim.lazyvim" ]; then
	mv ~/.config/nvim ~/.config/nvim.lazyvim
  mv ~/.config/nvim.astronvim ~/.config/nvim
	echo "lazyvim backuped"
  nvim
else if [ ! -d "~/.config/nvim.nvchad" ]; then
	mv ~/.config/nvim ~/.config/nvim.nvchad
  mv ~/.config/nvim.astronvim ~/.config/nvim
	echo "nvchad backuped"
  nvim
fi

