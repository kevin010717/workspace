#!/bin/bash

if [ ! -d "~/.config/nvim.nvchad" ]; then
	mv ~/.config/nvim ~/.config/nvim.nvchad
  mv ~/.config/nvim.lazyvim ~/.config/nvim
	echo "nvchad backuped"
  nvim
else if [ ! -d "~/.config/nvim.lunarvim" ]; then
	mv ~/.config/nvim ~/.config/nvim.lunarvim
  mv ~/.config/nvim.lazyvim ~/.config/nvim
	echo "lunarvim backuped"
  nvim
else if [ ! -d "~/.config/nvim.astronvim" ]; then
	mv ~/.config/nvim ~/.config/nvim.astronvim
  mv ~/.config/nvim.lazyvim ~/.config/nvim
	echo "astronvim backuped"
  nvim
fi

