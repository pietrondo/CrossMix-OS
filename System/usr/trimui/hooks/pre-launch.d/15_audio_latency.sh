#!/bin/sh
# Hook: Set optimal RetroArch audio and latency before game launch
RA_CFG=/mnt/SDCARD/RetroArch/retroarch.cfg
BACKUP="/tmp/ra_cfg_audio_backup_$$"

# Backup current values
grep -E "^(audio_resampler|audio_resampler_quality|video_frame_delay) " "$RA_CFG" > "$BACKUP" 2>/dev/null

# Apply optimal settings
sed -i 's/audio_resampler = .*/audio_resampler = "sinc"/' "$RA_CFG"
sed -i 's/audio_resampler_quality = .*/audio_resampler_quality = "3"/' "$RA_CFG"
sed -i 's/video_frame_delay = .*/video_frame_delay = "2"/' "$RA_CFG"

log_message "audio" "quality=sinc+3, frame_delay=2"
