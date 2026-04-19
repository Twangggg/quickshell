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

get_cpu_freq() {
    local freq
    freq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null | head -1)
    if [ -n "$freq" ]; then
        echo "$((freq / 1000))"
    else
        echo "0"
    fi
}

get_load_avg() {
    cat /proc/loadavg 2>/dev/null | awk '{print $1}'
}

get_uptime() {
    cat /proc/uptime 2>/dev/null | awk '{print $1}' | cut -d. -f1
}

get_processes() {
    ps -eo pid= 2>/dev/null | wc -l
}

get_disk_percent() {
    df -B1 / 2>/dev/null | awk 'NR==2 {print int($3*100/$2)}'
}

temp_val=$(get_cpu_temp)
ram_pct=$(get_ram_percent)
cpu_pct=$(get_cpu_percent)
cpu_freq=$(get_cpu_freq)
load_avg=$(get_load_avg)
uptime_sec=$(get_uptime)
proc_count=$(get_processes)
disk_pct=$(get_disk_percent)

jq -n -c --argjson temp "$temp_val" --argjson cpu "$cpu_pct" --argjson ram "$ram_pct" --argjson freq "$cpu_freq" --argjson load "$load_avg" --argjson uptime "$uptime_sec" --argjson procs "$proc_count" --argjson disk "$disk_pct" \
    '{temp: $temp, cpu: $cpu, ram: $ram, freq: $freq, load: $load, uptime: $uptime, procs: $procs, disk: $disk}'