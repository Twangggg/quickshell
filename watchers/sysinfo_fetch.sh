#!/usr/bin/env bash

get_cpu_temp() {
    local temp
    temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | head -n1)
    if [ -n "$temp" ]; then
        echo "$((temp / 1000))"
    else
        echo "0"
    fi
}

get_ram_percent() {
    local total available
    total=$(free -b 2>/dev/null | awk '/^Mem:/ {print $2}')
    available=$(free -b 2>/dev/null | awk '/^Mem:/ {print $7}')
    if [ -n "$total" ] && [ "$total" -gt 0 ]; then
        local used=$((total - available))
        echo "$((used * 100 / total))"
    else
        echo "50"
    fi
}

get_cpu_percent() {
    local line
    line=$(grep '^cpu ' /proc/stat 2>/dev/null)
    if [ -z "$line" ]; then
        echo "0"
        return
    fi
    set -- $line
    local user=$2 nice=$3 system=$4 idle=$5 iowait=$6 irq=$7 softirq=$8
    local total=$((user + nice + system + idle + iowait + irq + softirq))
    local active=$((user + nice + system))
    if [ "$total" -gt 0 ]; then
        echo "$((active * 100 / total))"
    else
        echo "0"
    fi
}

temp=$(get_cpu_temp)
ram=$(get_ram_percent)
cpu=$(get_cpu_percent)

jq -n -c --argjson temp "$temp" --argjson ram "$ram" --argjson cpu "$cpu" \
    '{temp: $temp, ram: $ram, cpu: $cpu}'