#!/bin/sh
# Boot Hook: Make all hooks executable on first boot
# Fixes permissions lost on Windows filesystem / git clone

HOOKS="/mnt/SDCARD/System/usr/trimui/hooks"
for d in boot.d pre-launch.d post-launch.d; do
    [ -d "$HOOKS/$d" ] && chmod +x "$HOOKS/$d"/*.sh 2>/dev/null
done
