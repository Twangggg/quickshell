#!/usr/bin/env bash
while inotifywait -q -e modify /sys/class/thermal/thermal_zone0/temp /proc/stat /proc/meminfo 2>/dev/null; do
    ~/.config/hypr/scripts/quickshell/watchers/sysinfo_fetch.sh
done