#!/bin/bash
#
# health-check.sh - System health monitoring script
# Usage: ./health-check.sh
#

set -euo pipefail

# --- Thresholds ---
CPU_THRESHOLD=80
RAM_THRESHOLD=80
DISK_THRESHOLD=80

# --- Colors ---
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# ---Global counters ---
WARNINGS=0

# --Helper function to print with color ---
print_status() {
    local lable="$1"
    local value="$2"
    local status="$3"

    local color
    case "$status" in
	OK)       color="$GREEN" ;;
	WARNING)  color="$YELLOW"; WARNINGS=$((WARNINGS + 1)) ;;
	CRITICAL) color="$RED";    WARNINGS=$((WARNINGS + 1)) ;;
	*)        color="$NC" ;;
    esac

    printf "%-10s %-40s ${color}[%s]${NC}]\n" "$lable" "$value" "$status"
}

# --- CPU Check ---
check_cpu() {
    local load
    load=$(awk '{print $1}' /proc/loadavg)
    local cores
    cores=$(nproc)
    local load_percent
    load_percent=$(awk -v l="$load" -v c="$cores" 'BEGIN {printf "%.0f", (l/c)*100}')
    
    local status="OK"
    if [ "$load_percent" -ge "$CPU_THRESHOLD" ]; then
	status="WARNING"
    fi

    print_status "[CPU]" "Load: $load (cores: $cores, ${load_percent}%)" "$status"
}

# --- RAM Check ---
check_ram() {
    local total used percent
    total=$(free -m | awk '/^Mem:/ {print $2}')
    used=$(free -m | awk '/^Mem:/ {print $3}')
    percent=$(awk -v u="$used" -v t="$total" 'BEGIN {printf "%.0f", (u/t)*100}') 

    local status="OK"
    if [ "$percent" -ge "$RAM_THRESHOLD" ]; then
	status="WARNING"
    fi

    print_status "[RAM]" "Used: ${used}MB / ${total}MB (${percent}%)" "$status"
}

# --- Disk Check ---
check_disk() {
    while read -r line; do
	local filesystem
	local percent
	local mount
	filesystem=$(echo "$line" | awk '{print $1}')
	percent=$(echo "$line" | awk '{print $5}' | tr -d '%')
	mount=$(echo "$line" | awk '{print $6}')

	local status="OK"
	if [ "$percent" -ge "$DISK_THRESHOLD" ]; then
            status="WARNING"
	fi

	print_status "[DISK]" "$mount ($filesystem): ${percent}%" "$status"
done < <(df -h --output=source,size,used,avail,pcent,target | tail -n +2 | grep -Ev '^(tmpfs|devtmpfs|none|overlay|udev)' | grep -v '/dev/sr')
}

# --- Services Check ---
SERVICES=("ssh" "cron")

check_services() {
    for service in "${SERVICES[@]}"; do
	local status="OK"
	local state

	if systemctl is-active --quiet "$service"; then
	    state="active"
	else
	    state="inactive"
	    status="WARNING"
	fi

	print_status "[SERVICE]" "$service: $state" "$status"
     done
}

# --- Testrun ---
# --- Header ---
echo "========================================"
echo "  System Health Check"
echo "========================================"
echo "Hostname: $(hostname)"
echo "Date:     $(date '+%Y-%m-%d %H:%M:%S')"
echo "Uptime:   $(uptime -p)"
echo "----------------------------------------"

# --- Checks ---
check_cpu
check_ram
check_disk
check_services

# --- Summary ---
echo "----------------------------------------"
if [ "$WARNINGS" -gt 0 ]; then
    echo -e "${YELLOW}Result: $WARNINGS warning(s) found${NC}"
    exit 1
else
    echo -e "${GREEN}Result: All checks passed${NC}"
    exit 0
fi
