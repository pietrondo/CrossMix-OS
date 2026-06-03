#!/bin/sh
# CrossMix-OS Debug Log Gatherer
# Collects logs, system info, and packages into a tarball.
# Output: /mnt/SDCARD/crossmix_debug_<date>.tar.gz

set -u
OUT="/mnt/SDCARD/crossmix_debug_$(date +%Y%m%d_%H%M%S).tar.gz"
T=$(mktemp -d)

if [ -d /mnt/SDCARD/System/var/logs ]; then
    cp -r /mnt/SDCARD/System/var/logs "$T/logs" 2>/dev/null
fi

dmesg > "$T/dmesg.txt" 2>/dev/null
cat /proc/cpuinfo > "$T/cpuinfo.txt" 2>/dev/null
free > "$T/meminfo.txt" 2>/dev/null
df -h > "$T/disk.txt" 2>/dev/null
uname -a > "$T/uname.txt" 2>/dev/null
cp /mnt/SDCARD/System/var/display_probe.txt "$T/display_probe.txt" 2>/dev/null

tar -czf "$OUT" -C "$T" . 2>/dev/null
rm -rf "$T"

if [ -f "$OUT" ]; then
    echo "Debug bundle created: $OUT"
    echo "Copy this file to your PC and send to the developer."
else
    echo "ERROR: Failed to create debug bundle"
    exit 1
fi
