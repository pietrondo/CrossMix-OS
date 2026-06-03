#!/bin/sh
# Hook: Record game session start time
echo "$(date +%s)" > "/tmp/game_timer_start_$$"
