#!/bin/bash
# check-gateway.sh - Data gathering for UDM Pro health check
# Part of the Capability Layering Pattern - deterministic operations only
#
# Usage:
#   check-gateway.sh --full           # Complete health check
#   check-gateway.sh --system         # System status only
#   check-gateway.sh --services       # Service status only
#   check-gateway.sh --network        # Network status only
#   check-gateway.sh --logs [count]   # Recent error logs
#   check-gateway.sh --quick          # Quick connectivity test
#
# Output: JSON for structured consumption by Claude
#
# Created: 2026-01-21

set -euo pipefail

# Configuration
UDM_HOST="${UDM_HOST:-gateway}"
SSH_OPTS="-o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new"

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] COMMAND

Commands:
  --full              Complete health check (all sections)
  --system            System status (uptime, memory, disk, CPU)
  --services          Service status (unifi-core, etc.)
  --network           Network status (interfaces, WAN, connections)
  --logs [count]      Recent error logs (default: 10)
  --quick             Quick connectivity test only

Options:
  -h, --help          Show this help

Examples:
  $(basename "$0") --full
  $(basename "$0") --system
  $(basename "$0") --logs 20

Environment:
  UDM_HOST            Gateway hostname (default: gateway)

EOF
    exit 0
}

# Test SSH connectivity
test_connectivity() {
    if ssh $SSH_OPTS "$UDM_HOST" "echo ok" &>/dev/null; then
        echo '{"reachable": true, "host": "'"$UDM_HOST"'", "timestamp": "'"$(date -Iseconds)"'"}'
    else
        echo '{"reachable": false, "host": "'"$UDM_HOST"'", "error": "SSH connection failed", "timestamp": "'"$(date -Iseconds)"'"}'
        exit 1
    fi
}

# Get system status
get_system_status() {
    # Collect data via SSH
    local uptime_info load_avg memory_info disk_info cpu_temp firmware

    # Get uptime and load
    uptime_info=$(ssh $SSH_OPTS "$UDM_HOST" "uptime" 2>/dev/null) || uptime_info="unavailable"

    # Parse load average
    load_avg=$(echo "$uptime_info" | grep -oP 'load average: \K[\d.]+' | head -1) || load_avg="0"

    # Parse uptime days
    local uptime_days="0"
    if [[ "$uptime_info" =~ ([0-9]+)\ day ]]; then
        uptime_days="${BASH_REMATCH[1]}"
    fi

    # Get memory info
    memory_info=$(ssh $SSH_OPTS "$UDM_HOST" "free -m" 2>/dev/null) || memory_info=""
    local mem_total mem_used mem_percent
    if [[ -n "$memory_info" ]]; then
        mem_total=$(echo "$memory_info" | awk '/^Mem:/ {print $2}')
        mem_used=$(echo "$memory_info" | awk '/^Mem:/ {print $3}')
        mem_percent=$(echo "scale=1; $mem_used * 100 / $mem_total" | bc 2>/dev/null) || mem_percent="0"
    else
        mem_total="0"
        mem_used="0"
        mem_percent="0"
    fi

    # Get disk info
    disk_info=$(ssh $SSH_OPTS "$UDM_HOST" "df -h / /var/log /persistent 2>/dev/null" 2>/dev/null) || disk_info=""
    local disk_root disk_log disk_persistent
    disk_root=$(echo "$disk_info" | awk '$6=="/" {gsub(/%/,"",$5); print $5}') || disk_root="0"
    disk_log=$(echo "$disk_info" | awk '$6=="/var/log" {gsub(/%/,"",$5); print $5}') || disk_log="0"
    disk_persistent=$(echo "$disk_info" | awk '$6=="/persistent" {gsub(/%/,"",$5); print $5}') || disk_persistent="0"

    # Get CPU temperature (if available)
    cpu_temp=$(ssh $SSH_OPTS "$UDM_HOST" "cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null" 2>/dev/null) || cpu_temp=""
    if [[ -n "$cpu_temp" && "$cpu_temp" =~ ^[0-9]+$ ]]; then
        cpu_temp=$(echo "scale=1; $cpu_temp / 1000" | bc 2>/dev/null) || cpu_temp="0"
    else
        cpu_temp="null"
    fi

    # Get firmware version
    firmware=$(ssh $SSH_OPTS "$UDM_HOST" "ubnt-device-info firmware 2>/dev/null || cat /etc/version 2>/dev/null || echo unknown" 2>/dev/null) || firmware="unknown"

    cat << EOF
{
  "uptime_days": $uptime_days,
  "load_average": $load_avg,
  "memory": {
    "total_mb": $mem_total,
    "used_mb": $mem_used,
    "percent": $mem_percent
  },
  "disk": {
    "root_percent": ${disk_root:-0},
    "var_log_percent": ${disk_log:-0},
    "persistent_percent": ${disk_persistent:-0}
  },
  "cpu_temp_c": $cpu_temp,
  "firmware": "$firmware",
  "timestamp": "$(date -Iseconds)"
}
EOF
}

# Get service status
get_services_status() {
    local services=("unifi-core" "unifi-cloud-agent" "unifi-access" "mongod")
    local service_statuses=()

    for service in "${services[@]}"; do
        local status
        status=$(ssh $SSH_OPTS "$UDM_HOST" "systemctl is-active $service 2>/dev/null" 2>/dev/null) || status="unknown"
        service_statuses+=("{\"name\": \"$service\", \"status\": \"$status\"}")
    done

    # Check for failed services
    local failed_services
    failed_services=$(ssh $SSH_OPTS "$UDM_HOST" "systemctl --failed --no-legend 2>/dev/null | wc -l" 2>/dev/null) || failed_services="0"

    cat << EOF
{
  "services": [$(IFS=,; echo "${service_statuses[*]}")],
  "failed_count": $failed_services,
  "timestamp": "$(date -Iseconds)"
}
EOF
}

# Get network status
get_network_status() {
    # WAN interface
    local wan_ip wan_status
    wan_ip=$(ssh $SSH_OPTS "$UDM_HOST" "ip -4 addr show eth9 2>/dev/null | grep -oP 'inet \K[\d.]+' | head -1" 2>/dev/null) || wan_ip=""
    [[ -n "$wan_ip" ]] && wan_status="up" || wan_status="down"

    # LAN interface
    local lan_ip
    lan_ip=$(ssh $SSH_OPTS "$UDM_HOST" "ip -4 addr show br0 2>/dev/null | grep -oP 'inet \K[\d.]+' | head -1" 2>/dev/null) || lan_ip=""

    # Active connections
    local active_connections
    active_connections=$(ssh $SSH_OPTS "$UDM_HOST" "cat /proc/net/nf_conntrack 2>/dev/null | wc -l" 2>/dev/null) || active_connections="0"

    # WAN connectivity test
    local wan_connectivity
    if ssh $SSH_OPTS "$UDM_HOST" "ping -c 1 -W 2 8.8.8.8 &>/dev/null" 2>/dev/null; then
        wan_connectivity="ok"
    else
        wan_connectivity="failed"
    fi

    # VLAN interfaces
    local vlans=()
    for vlan in br2 br3 br4 br6; do
        local vlan_ip
        vlan_ip=$(ssh $SSH_OPTS "$UDM_HOST" "ip -4 addr show $vlan 2>/dev/null | grep -oP 'inet \K[\d.]+' | head -1" 2>/dev/null) || vlan_ip=""
        if [[ -n "$vlan_ip" ]]; then
            vlans+=("{\"interface\": \"$vlan\", \"ip\": \"$vlan_ip\"}")
        fi
    done

    cat << EOF
{
  "wan": {
    "interface": "eth9",
    "ip": "${wan_ip:-null}",
    "status": "$wan_status"
  },
  "lan": {
    "interface": "br0",
    "ip": "${lan_ip:-192.168.1.1}"
  },
  "wan_connectivity": "$wan_connectivity",
  "active_connections": $active_connections,
  "vlans": [$(IFS=,; echo "${vlans[*]}")],
  "timestamp": "$(date -Iseconds)"
}
EOF
}

# Get recent logs
get_logs() {
    local count="${1:-10}"
    local errors=()

    # Get recent errors from journalctl
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            local escaped_line
            escaped_line=$(echo "$line" | sed 's/"/\\"/g' | tr -d '\n\r')
            errors+=("\"$escaped_line\"")
        fi
    done < <(ssh $SSH_OPTS "$UDM_HOST" "journalctl -p err -n $count --no-pager 2>/dev/null | tail -$count" 2>/dev/null)

    # Get failed SSH attempts
    local failed_ssh
    failed_ssh=$(ssh $SSH_OPTS "$UDM_HOST" "journalctl -u ssh -n 100 --no-pager 2>/dev/null | grep -c 'Failed password' || echo 0" 2>/dev/null) || failed_ssh="0"

    # Get firewall drops (last hour)
    local fw_drops
    fw_drops=$(ssh $SSH_OPTS "$UDM_HOST" "journalctl -k --since '1 hour ago' --no-pager 2>/dev/null | grep -c 'DROP' || echo 0" 2>/dev/null) || fw_drops="0"

    # Build errors JSON
    local errors_json=""
    if [[ ${#errors[@]} -gt 0 ]]; then
        errors_json=$(IFS=,; echo "${errors[*]}")
    fi

    cat << EOF
{
  "recent_errors": [$errors_json],
  "error_count": ${#errors[@]},
  "failed_ssh_attempts": $failed_ssh,
  "firewall_drops_1h": $fw_drops,
  "timestamp": "$(date -Iseconds)"
}
EOF
}

# Full health check
full_check() {
    # Test connectivity first
    if ! ssh $SSH_OPTS "$UDM_HOST" "echo ok" &>/dev/null; then
        echo '{"error": "SSH connection failed", "host": "'"$UDM_HOST"'", "timestamp": "'"$(date -Iseconds)"'"}'
        exit 1
    fi

    local system services network logs

    system=$(get_system_status)
    services=$(get_services_status)
    network=$(get_network_status)
    logs=$(get_logs 10)

    cat << EOF
{
  "host": "$UDM_HOST",
  "system": $system,
  "services": $services,
  "network": $network,
  "logs": $logs,
  "timestamp": "$(date -Iseconds)"
}
EOF
}

# Main
main() {
    local command=""
    local log_count=10

    while [[ $# -gt 0 ]]; do
        case $1 in
            --full)
                command="full"
                shift
                ;;
            --system)
                command="system"
                shift
                ;;
            --services)
                command="services"
                shift
                ;;
            --network)
                command="network"
                shift
                ;;
            --logs)
                command="logs"
                if [[ "${2:-}" =~ ^[0-9]+$ ]]; then
                    log_count="$2"
                    shift
                fi
                shift
                ;;
            --quick)
                command="quick"
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                echo "Unknown option: $1" >&2
                usage
                ;;
        esac
    done

    case "$command" in
        full)
            full_check
            ;;
        system)
            get_system_status
            ;;
        services)
            get_services_status
            ;;
        network)
            get_network_status
            ;;
        logs)
            get_logs "$log_count"
            ;;
        quick)
            test_connectivity
            ;;
        *)
            usage
            ;;
    esac
}

main "$@"
