#!/bin/sh
# CrossMix-OS Display Control Discovery
# Probes available DRM/KMS and backlight controls on TrimUI Smart Pro.
# Run on-device to find what's controllable.
# Usage: sh display_probe.sh > display_probe_output.txt

echo "=== Display Probe $(date) ==="
echo ""

echo "--- DRM connectors ---"
for c in /sys/class/drm/card*/card*-*/; do
    [ -d "$c" ] || continue
    NAME=$(cat "$c/name" 2>/dev/null || echo "?")
    STATUS=$(cat "$c/status" 2>/dev/null || echo "?")
    echo "Connector: $(basename $c) ($NAME) status=$STATUS"
    for prop in brightness contrast saturation hue; do
        if [ -f "$c/$prop" ]; then
            echo "  $prop = $(cat $c/$prop 2>/dev/null)"
        fi
    done
done

echo ""
echo "--- Backlight ---"
for b in /sys/class/backlight/*/; do
    [ -d "$b" ] || continue
    echo "Backlight: $(basename $(dirname $b))"
    echo "  max_brightness = $(cat ${b}max_brightness 2>/dev/null)"
    echo "  brightness = $(cat ${b}brightness 2>/dev/null)"
    echo "  actual_brightness = $(cat ${b}actual_brightness 2>/dev/null)"
done

echo ""
echo "--- Framebuffer ---"
cat /sys/class/graphics/fb0/name 2>/dev/null
cat /sys/class/graphics/fb0/virtual_size 2>/dev/null

echo ""
echo "--- DRM properties ---"
for card in /sys/class/drm/card[0-9]; do
    echo "Card: $(basename $card)"
    modetest -M $(basename $card) 2>/dev/null | grep -E "^(Connector|CRTC|Plane|  [0-9]+:|    [a-z_]+:)" | head -20
done

echo ""
echo "=== Done ==="
