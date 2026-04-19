#!/bin/bash

# CPU Usage
cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')

# RAM Usage
mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
mem_free=$(grep MemFree /proc/meminfo | awk '{print $2}')
mem_cached=$(grep ^Cached /proc/meminfo | awk '{print $2}')
mem_buffers=$(grep Buffers /proc/meminfo | awk '{print $2}')
mem_reclaimable=$(grep SReclaimable /proc/meminfo | awk '{print $2}')
mem_used=$((mem_total - mem_free - mem_buffers - mem_cached - mem_reclaimable))
ram_percent=$(awk "BEGIN {print ($mem_used / $mem_total) * 100}")

# Thông tin bổ sung cho Dashboard
cpu_model=$(lscpu | grep "Model name" | sed 's/Model name: *//' | awk '{print $1,$2,$3}')
cpu_temp=$(sensors 2>/dev/null | grep -E "Package id 0|Core 0" | head -1 | awk '{print $4}' | sed 's/+//')
[ -z "$cpu_temp" ] && cpu_temp="N/A"
uptime_str=$(uptime -p | sed 's/up //')

# Xuất JSON
echo "{\"cpu\": $cpu_usage, \"ram\": $ram_percent, \"cpuModel\": \"$cpu_model\", \"temp\": \"$cpu_temp\", \"uptime\": \"$uptime_str\"}"