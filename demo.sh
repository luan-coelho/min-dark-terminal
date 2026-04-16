#!/usr/bin/env bash
# Min Dark Terminal — Demo script for screenshots
# Run this inside the Min Dark profile to showcase all colors.

printf "\n"
printf "  \033[1;37m Min Dark Terminal \033[0m\n"
printf "  \033[0;90m Port of Min Theme by Miguel Solorio \033[0m\n"
printf "\n"

# ── Color blocks ──────────────────────────────────────────────────────────── #
printf "  \033[0;37m Normal \033[0m  "
for i in 0 1 2 3 4 5 6 7; do
  printf "\033[48;5;${i}m    \033[0m"
done
printf "\n"

printf "  \033[0;37m Bright \033[0m  "
for i in 8 9 10 11 12 13 14 15; do
  printf "\033[48;5;${i}m    \033[0m"
done
printf "\n\n"

# ── Color names ───────────────────────────────────────────────────────────── #
printf "  \033[30m  black  \033[0m \033[31m  red    \033[0m \033[32m  green  \033[0m \033[33m  yellow \033[0m \033[34m  blue   \033[0m \033[35m  magenta\033[0m \033[36m  cyan   \033[0m \033[37m  white  \033[0m\n"
printf "  \033[90m  black  \033[0m \033[91m  red    \033[0m \033[92m  green  \033[0m \033[93m  yellow \033[0m \033[94m  blue   \033[0m \033[95m  magenta\033[0m \033[96m  cyan   \033[0m \033[97m  white  \033[0m\n"
printf "\n"

# ── Fake prompt ───────────────────────────────────────────────────────────── #
printf "  \033[34m~/projects/min-dark-terminal\033[0m \033[35mmain\033[0m\n"
printf "  \033[37m>\033[0m git status\n"
printf "  \033[32mOn branch main\033[0m\n"
printf "  \033[32mnothing to commit, working tree clean\033[0m\n"
printf "\n"

printf "  \033[34m~/projects/min-dark-terminal\033[0m \033[35mmain \033[31m*\033[0m\n"
printf "  \033[37m>\033[0m ls -la\n"
printf "  \033[34mdrwxr-xr-x\033[0m  .git/\n"
printf "  \033[34mdrwxr-xr-x\033[0m  gnome-terminal/\n"
printf "  \033[34mdrwxr-xr-x\033[0m  oh-my-zsh/\n"
printf "  \033[37m-rw-r--r--\033[0m  README.md\n"
printf "  \033[32m-rwxr-xr-x\033[0m  install.sh\n"
printf "  \033[32m-rwxr-xr-x\033[0m  uninstall.sh\n"
printf "  \033[37m-rw-r--r--\033[0m  LICENSE\n"
printf "\n"

# ── Syntax highlight sample ───────────────────────────────────────────────── #
printf "  \033[90m# sample.py\033[0m\n"
printf "  \033[31mfrom\033[0m \033[37mos\033[0m \033[31mimport\033[0m \033[37mpath\033[0m\n"
printf "\n"
printf "  \033[31mdef\033[0m \033[35mgreet\033[0m\033[37m(\033[0m\033[33mname\033[0m\033[37m):\033[0m\n"
printf "      \033[34mmessage\033[0m \033[37m=\033[0m \033[33mf\"Hello, \033[97m{name}\033[33m!\"\033[0m\n"
printf "      \033[31mreturn\033[0m \033[34mmessage\033[0m\n"
printf "\n"
printf "  \033[35mgreet\033[0m\033[37m(\033[0m\033[33m\"world\"\033[0m\033[37m)\033[0m  \033[90m# => Hello, world!\033[0m\n"
printf "\n"
