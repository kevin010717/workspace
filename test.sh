#!/bin/bash

commands=("sl" "cmatrix" "nyancat")
command=${commands[$RANDOM % ${#commands[@]}]}
$command

commands=("sl" "cmatrix" "nyancat")
command=${commands[$RANDOM % ${#commands[@]}]}
$command
