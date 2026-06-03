#!/bin/sh
# Hook: NTP time sync at boot/first launch if WiFi is up
# Only syncs once per boot (flag file)

FLAG="/tmp/ntp_synced"
[ -f "$FLAG" ] && exit 0

# Check if WiFi has IP (from enable_wifi in common_functions.sh pattern)
IP=$(ip route get 1 2>/dev/null | awk '/src/ {print $NF; exit}')
[ -z "$IP" ] && exit 0

echo "Syncing time..."
/usr/sbin/ntpd -p ntp5.aliyun.com -p 0.openwrt.pool.ntp.org -n -q 2>/dev/null && touch "$FLAG"
log_message "ntp" "time synced"
