#!/bin/sh
# CrossMix-OS shared environment setup
# Source this file in scripts that need CrossMix tools/binaries

_CM_ENV_LOADED=1

export PATH="/mnt/SDCARD/System/bin:/mnt/SDCARD/System/usr/trimui/scripts:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
