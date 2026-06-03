#!/bin/sh
# Hook: Enable RetroAchievements on supported cores
# Reads credentials from System/etc/achievements.json
# Sets cheevos_* in retroarch.cfg before RetroArch starts

CFG=/mnt/SDCARD/System/etc/achievements.json
RA_CFG=/mnt/SDCARD/RetroArch/retroarch.cfg
[ -f "$CFG" ] || exit 0

USER=$(jq -r '.username' "$CFG")
TOKEN=$(jq -r '.token' "$CFG")
[ "$USER" = "null" ] || [ -z "$USER" ] && exit 0
[ "$TOKEN" = "null" ] || [ -z "$TOKEN" ] && exit 0

sed -i "s/cheevos_enable = .*/cheevos_enable = \"true\"/" "$RA_CFG"
sed -i "s/cheevos_username = .*/cheevos_username = \"$USER\"/" "$RA_CFG"
sed -i "s/cheevos_token = .*/cheevos_token = \"$TOKEN\"/" "$RA_CFG"
log_message "cheevos" "enabled for $USER"
