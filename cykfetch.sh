#!/bin/bash

# arch only

# colors
red="\e[31m"
reset="\e[0m"

# preload info
user=$(whoami)
host=$(uname -n)
os=$(source /etc/os-release && echo "$PRETTY_NAME")
kernel=$(uname -r)
kernelver=$(uname -v)

# uptime parsing
uptime_seconds=$(LC_ALL=C awk '{print int($1)}' /proc/uptime)
uptime_hours=$(( uptime_seconds / 3600 ))
uptime_minutes=$(( (uptime_seconds / 60) % 60 ))
if (( uptime_hours == 0 )); then
    uptime="${uptime_minutes} minutes"
else
    uptime="${uptime_hours} hours, ${uptime_minutes} minutes"
fi

pkgs=$(pacman -Qq | wc -l)
mem_total=$(awk '/MemTotal/ {print int($2/1024)"m"}' /proc/meminfo)
mem_available=$(awk '/MemAvailable/ {print int($2/1024)"m"}' /proc/meminfo)

# get CPU info only once
cpu=$(awk -F ': ' '/model name/ {print $2; exit}' /proc/cpuinfo | sed 's/^[ \t]*//')

# memory used = total - available
mem_used=$(awk "BEGIN {print int(${mem_total%m} - ${mem_available%m}) \"m\"}")

# gpu detection
gpu=""

# check for nvidia-smi first, then fallback to lspci if not available
if command -v nvidia-smi &> /dev/null; then
    gpu=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null)
    [ -z "$gpu" ] && gpu="NVIDIA (open source, nouveau)"
elif command -v lspci &> /dev/null; then
    gpu=$(lspci | grep -Ei 'vga|3d|display' | awk -F ': ' '{print $2}')
fi

# output
echo -e "$red"
cat << eof
       /\\       ${user}@${host}
      /  \\      os: ${os}
     /\\   \\     kernel: ${kernel}
    /      \\    uptime: ${uptime}
   /   ,,   \\   packages: ${pkgs}
  /   |  |  -   memory: ${mem_used} / ${mem_total}
 /_-''    ''-_\\ kernel version: ${kernelver}
                cpu: ${cpu}
                gpu: ${gpu}
eof
echo -e "$reset"

# thanks y'all curious people for reading this script, listen to my favorite song: https://www.youtube.com/watch?v=DuezmOvfWpA
