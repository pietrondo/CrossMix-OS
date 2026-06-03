#!/bin/sh
# Boot Hook: NTP time sync (runs once at boot if WiFi is up)
# Creates flag to prevent duplicate sync in pre-launch hook

IP=$(ip route get 1 2>/dev/null | awk '/src/ {print $NF; exit}')
[ -z "$IP" ] && exit 0

/usr/sbin/ntpd -p ntp5.aliyun.com -p 0.openwrt.pool.ntp.org -n -q 2>/dev/null && touch /tmp/ntp_synced
