#!/bin/bash

if [ ! -d "~/.config/nvim.lunarvim" ]; then
	mv ~/.config/nvim ~/.config/nvim.lunarvim
  mv ~/.config/nvim.nvchad ~/.config/nvim
	echo "lunarvim backuped"
  nvim
else if [ ! -d "~/.config/nvim.lazyvim" ]; then
	mv ~/.config/nvim ~/.config/nvim.lazyvim
  mv ~/.config/nvim.nvchad ~/.config/nvim
	echo "lazyvim backuped"
  nvim
else if [ ! -d "~/.config/nvim.astronvim" ]; then
	mv ~/.config/nvim ~/.config/nvim.astronvim
  mv ~/.config/nvim.nvchad ~/.config/nvim
	echo "astronvim backuped"
  nvim
fi
#
