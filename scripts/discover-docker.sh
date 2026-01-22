#!/bin/bash
# discover-docker.sh - Data gathering for Docker container discovery
# Part of the Capability Layering Pattern - deterministic operations only
#
# Usage:
#   discover-docker.sh --info <container>         # Container info as JSON
#   discover-docker.sh --watchtower <container>   # Watchtower label status
#   discover-docker.sh --compose <container>      # Find compose file
#   discover-docker.sh --logs <container> [count] # Recent logs
#   discover-docker.sh --list [filter]            # List containers
#   discover-docker.sh --full <container>         # Complete discovery
#
# Output: JSON for structured consumption by Claude
#
# Created: 2026-01-21

set -euo pipefail

# Configuration
DOCKER_COMPOSE_PATHS=("/opt" "/home" "$HOME/Docker" "$HOME/mydocker")

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] COMMAND

Commands:
  --info <container>           Container inspection as JSON
  --watchtower <container>     Watchtower auto-update label status
  --compose <container>        Find compose file location
  --logs <container> [count]   Recent container logs (default: 50)
  --list [filter]              List containers (optional name filter)
  --full <container>           Complete discovery (all sections)

Options:
  -h, --help                   Show this help

Examples:
  $(basename "$0") --info n8n
  $(basename "$0") --watchtower homepage
  $(basename "$0") --full caddy
  $(basename "$0") --list

EOF
    exit 0
}

# Get container info
get_container_info() {
    local container="$1"

    # Check if container exists
    if ! docker inspect "$container" &>/dev/null; then
        echo '{"error": "Container not found", "container": "'"$container"'"}'
        exit 1
    fi

    # Get comprehensive info
    local inspect_json
    inspect_json=$(docker inspect "$container" 2>/dev/null)

    # Parse key fields
    local name image status created
    local ports volumes networks labels
    local restart_policy health_status

    name=$(echo "$inspect_json" | jq -r '.[0].Name' | sed 's/^\///')
    image=$(echo "$inspect_json" | jq -r '.[0].Config.Image')
    status=$(echo "$inspect_json" | jq -r '.[0].State.Status')
    created=$(echo "$inspect_json" | jq -r '.[0].Created')
    restart_policy=$(echo "$inspect_json" | jq -r '.[0].HostConfig.RestartPolicy.Name')
    health_status=$(echo "$inspect_json" | jq -r '.[0].State.Health.Status // "none"')

    # Get ports
    ports=$(echo "$inspect_json" | jq -c '.[0].NetworkSettings.Ports | to_entries | map(select(.value != null) | {port: .key, bindings: .value})')

    # Get volumes
    volumes=$(echo "$inspect_json" | jq -c '.[0].Mounts | map({source: .Source, destination: .Destination, type: .Type, mode: .Mode})')

    # Get networks
    networks=$(echo "$inspect_json" | jq -c '.[0].NetworkSettings.Networks | keys')

    # Get labels (useful ones only)
    labels=$(echo "$inspect_json" | jq -c '.[0].Config.Labels | to_entries | map(select(.key | (contains("watchtower") or contains("homepage") or contains("traefik") or contains("compose"))))')

    # Get environment (filter secrets)
    local env_safe
    env_safe=$(echo "$inspect_json" | jq -c '.[0].Config.Env | map(select(. | (contains("PASSWORD") or contains("SECRET") or contains("KEY") or contains("TOKEN")) | not))')

    cat << EOF
{
  "container": "$name",
  "image": "$image",
  "status": "$status",
  "health": "$health_status",
  "created": "$created",
  "restart_policy": "$restart_policy",
  "ports": $ports,
  "volumes": $volumes,
  "networks": $networks,
  "labels": $labels,
  "environment": $env_safe,
  "timestamp": "$(date -Iseconds)"
}
EOF
}

# Check Watchtower labels
check_watchtower() {
    local container="$1"

    if ! docker inspect "$container" &>/dev/null; then
        echo '{"error": "Container not found", "container": "'"$container"'"}'
        exit 1
    fi

    local labels
    labels=$(docker inspect --format='{{json .Config.Labels}}' "$container" 2>/dev/null)

    local watchtower_enable watchtower_scope watchtower_monitor
    watchtower_enable=$(echo "$labels" | jq -r '.["com.centurylinklabs.watchtower.enable"] // "not_set"')
    watchtower_scope=$(echo "$labels" | jq -r '.["com.centurylinklabs.watchtower.scope"] // "not_set"')
    watchtower_monitor=$(echo "$labels" | jq -r '.["com.centurylinklabs.watchtower.monitor-only"] // "not_set"')

    # Determine status
    local status recommendation
    if [[ "$watchtower_enable" == "true" && "$watchtower_scope" != "not_set" ]]; then
        status="complete"
        recommendation="none"
    elif [[ "$watchtower_scope" != "not_set" && "$watchtower_enable" == "not_set" ]]; then
        status="incomplete"
        recommendation="Add com.centurylinklabs.watchtower.enable=true"
    else
        status="missing"
        recommendation="Add Watchtower labels: enable=true, scope=prod|dev"
    fi

    cat << EOF
{
  "container": "$container",
  "watchtower": {
    "enable": "$watchtower_enable",
    "scope": "$watchtower_scope",
    "monitor_only": "$watchtower_monitor"
  },
  "status": "$status",
  "recommendation": "$recommendation",
  "timestamp": "$(date -Iseconds)"
}
EOF
}

# Find compose file
find_compose() {
    local container="$1"
    local compose_files=()

    # Check container labels for compose project
    local compose_project compose_file
    compose_project=$(docker inspect --format='{{index .Config.Labels "com.docker.compose.project.working_dir"}}' "$container" 2>/dev/null) || compose_project=""
    compose_file=$(docker inspect --format='{{index .Config.Labels "com.docker.compose.project.config_files"}}' "$container" 2>/dev/null) || compose_file=""

    if [[ -n "$compose_project" && -f "$compose_project/docker-compose.yaml" ]]; then
        compose_files+=("$compose_project/docker-compose.yaml")
    elif [[ -n "$compose_project" && -f "$compose_project/docker-compose.yml" ]]; then
        compose_files+=("$compose_project/docker-compose.yml")
    elif [[ -n "$compose_file" && -f "$compose_file" ]]; then
        compose_files+=("$compose_file")
    fi

    # Search common locations if not found via labels
    if [[ ${#compose_files[@]} -eq 0 ]]; then
        for path in "${DOCKER_COMPOSE_PATHS[@]}"; do
            if [[ -d "$path" ]]; then
                while IFS= read -r file; do
                    if [[ -n "$file" && -f "$file" ]]; then
                        # Check if compose file contains the container name
                        if grep -qi "$container" "$file" 2>/dev/null; then
                            compose_files+=("$file")
                        fi
                    fi
                done < <(find "$path" -maxdepth 4 -type f \( -name "docker-compose.yaml" -o -name "docker-compose.yml" -o -name "compose.yaml" -o -name "compose.yml" \) 2>/dev/null | head -20)
            fi
        done
    fi

    # Build JSON array
    local files_json=""
    if [[ ${#compose_files[@]} -gt 0 ]]; then
        local first=true
        for f in "${compose_files[@]}"; do
            if $first; then
                first=false
                files_json="\"$f\""
            else
                files_json="$files_json, \"$f\""
            fi
        done
    fi

    cat << EOF
{
  "container": "$container",
  "compose_project": "${compose_project:-null}",
  "compose_files": [$files_json],
  "count": ${#compose_files[@]},
  "timestamp": "$(date -Iseconds)"
}
EOF
}

# Get container logs
get_logs() {
    local container="$1"
    local count="${2:-50}"

    if ! docker inspect "$container" &>/dev/null; then
        echo '{"error": "Container not found", "container": "'"$container"'"}'
        exit 1
    fi

    local logs=()
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            local escaped
            escaped=$(echo "$line" | sed 's/"/\\"/g' | tr -d '\n\r' | cut -c1-500)
            logs+=("\"$escaped\"")
        fi
    done < <(docker logs --tail "$count" "$container" 2>&1 | tail -"$count")

    # Check for error patterns
    local error_count warning_count
    error_count=$(docker logs --tail 100 "$container" 2>&1 | grep -ci "error\|exception\|fatal\|failed" || echo "0")
    warning_count=$(docker logs --tail 100 "$container" 2>&1 | grep -ci "warn\|warning" || echo "0")

    # Build logs JSON
    local logs_json=""
    if [[ ${#logs[@]} -gt 0 ]]; then
        logs_json=$(IFS=,; echo "${logs[*]}")
    fi

    cat << EOF
{
  "container": "$container",
  "log_lines": [$logs_json],
  "line_count": ${#logs[@]},
  "recent_errors": $error_count,
  "recent_warnings": $warning_count,
  "timestamp": "$(date -Iseconds)"
}
EOF
}

# List containers
list_containers() {
    local filter="${1:-}"
    local containers=()

    while IFS='|' read -r name image status ports; do
        if [[ -n "$name" ]]; then
            # Apply filter if provided
            if [[ -z "$filter" ]] || [[ "$name" == *"$filter"* ]] || [[ "$image" == *"$filter"* ]]; then
                containers+=("{\"name\": \"$name\", \"image\": \"$image\", \"status\": \"$status\", \"ports\": \"$ports\"}")
            fi
        fi
    done < <(docker ps -a --format "{{.Names}}|{{.Image}}|{{.Status}}|{{.Ports}}" 2>/dev/null)

    # Build containers JSON
    local containers_json=""
    if [[ ${#containers[@]} -gt 0 ]]; then
        containers_json=$(IFS=,; echo "${containers[*]}")
    fi

    cat << EOF
{
  "containers": [$containers_json],
  "count": ${#containers[@]},
  "filter": "${filter:-none}",
  "timestamp": "$(date -Iseconds)"
}
EOF
}

# Full discovery
full_discovery() {
    local container="$1"

    if ! docker inspect "$container" &>/dev/null; then
        echo '{"error": "Container not found", "container": "'"$container"'"}'
        exit 1
    fi

    local info watchtower compose logs

    info=$(get_container_info "$container")
    watchtower=$(check_watchtower "$container")
    compose=$(find_compose "$container")
    logs=$(get_logs "$container" 20)

    # Check for existing documentation
    local doc_exists="false"
    local doc_path="$HOME/AIProjects/.claude/context/systems/docker/$container.md"
    [[ -f "$doc_path" ]] && doc_exists="true"

    cat << EOF
{
  "container": "$container",
  "info": $info,
  "watchtower": $watchtower,
  "compose": $compose,
  "logs": $logs,
  "documentation": {
    "exists": $doc_exists,
    "path": "$doc_path"
  },
  "timestamp": "$(date -Iseconds)"
}
EOF
}

# Main
main() {
    local command=""
    local container=""
    local filter=""
    local log_count=50

    while [[ $# -gt 0 ]]; do
        case $1 in
            --info)
                command="info"
                container="${2:-}"
                shift 2 || { echo '{"error": "Container name required"}'; exit 1; }
                ;;
            --watchtower)
                command="watchtower"
                container="${2:-}"
                shift 2 || { echo '{"error": "Container name required"}'; exit 1; }
                ;;
            --compose)
                command="compose"
                container="${2:-}"
                shift 2 || { echo '{"error": "Container name required"}'; exit 1; }
                ;;
            --logs)
                command="logs"
                container="${2:-}"
                shift 2 || { echo '{"error": "Container name required"}'; exit 1; }
                if [[ "${1:-}" =~ ^[0-9]+$ ]]; then
                    log_count="$1"
                    shift
                fi
                ;;
            --list)
                command="list"
                filter="${2:-}"
                [[ -n "$filter" && "$filter" != "--"* ]] && shift
                shift
                ;;
            --full)
                command="full"
                container="${2:-}"
                shift 2 || { echo '{"error": "Container name required"}'; exit 1; }
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
        info)
            get_container_info "$container"
            ;;
        watchtower)
            check_watchtower "$container"
            ;;
        compose)
            find_compose "$container"
            ;;
        logs)
            get_logs "$container" "$log_count"
            ;;
        list)
            list_containers "$filter"
            ;;
        full)
            full_discovery "$container"
            ;;
        *)
            usage
            ;;
    esac
}

main "$@"
