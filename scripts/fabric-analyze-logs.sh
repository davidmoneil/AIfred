#!/bin/bash
# fabric-analyze-logs.sh - AI-powered log analysis for Docker containers
# Part of CLI capability layer
#
# Analyzes container logs using fabric's analyze_logs pattern to identify:
# - Patterns and trends
# - Anomalies and errors
# - Security concerns
# - Actionable recommendations
#
# Usage:
#   fabric-analyze-logs.sh <container>           # Last 50 lines
#   fabric-analyze-logs.sh <container> --lines 100
#   fabric-analyze-logs.sh --file /var/log/app.log
#   docker logs nginx 2>&1 | fabric-analyze-logs.sh --stdin

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WRAPPER="${SCRIPT_DIR}/fabric-wrapper.sh"

# Defaults
DEFAULT_LINES=50

show_help() {
    cat << 'EOF'
Usage: fabric-analyze-logs.sh [container|--file path|--stdin] [options]

AI-powered analysis of logs from Docker containers or files.

Arguments:
  <container>     Docker container name to analyze

Options:
  --lines, -n <N>   Number of log lines to analyze (default: 50)
  --file <path>     Analyze a log file instead of container
  --stdin           Read logs from stdin
  --since <time>    Docker logs --since (e.g., "1h", "2024-01-01")
  --model <m>       Force model (32b for thorough, 7b for fast)
  --output <file>   Save analysis to file
  --quiet           Suppress status messages
  --help            Show this help

Examples:
  fabric-analyze-logs.sh prometheus              # Last 50 lines
  fabric-analyze-logs.sh nginx --lines 200       # More context
  fabric-analyze-logs.sh pai-backend --since 1h  # Recent logs
  fabric-analyze-logs.sh --file /var/log/syslog --lines 100
  journalctl -u docker --no-pager | fabric-analyze-logs.sh --stdin

Output Sections:
  - Overview: What the logs show
  - Key Observations: Important findings
  - Patterns/Anomalies: Trends and issues
  - Recommendations: Suggested actions
EOF
    exit 0
}

main() {
    local container=""
    local log_file=""
    local use_stdin=false
    local lines=$DEFAULT_LINES
    local since=""
    local model_arg=""
    local output_file=""
    local quiet=""
    local log_content=""

    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --help|-h) show_help ;;
            --lines|-n) lines="$2"; shift 2 ;;
            --file) log_file="$2"; shift 2 ;;
            --stdin) use_stdin=true; shift ;;
            --since) since="$2"; shift 2 ;;
            --model) model_arg="--model-only $2"; shift 2 ;;
            --output) output_file="$2"; shift 2 ;;
            --quiet|-q) quiet="--quiet"; shift ;;
            -*)
                echo "Unknown option: $1" >&2
                echo "Use --help for usage information" >&2
                exit 1
                ;;
            *)
                container="$1"
                shift
                ;;
        esac
    done

    # Get log content based on source
    if $use_stdin; then
        log_content=$(head -n "$lines")
        [ -z "$log_content" ] && { echo "No input from stdin" >&2; exit 1; }

    elif [ -n "$log_file" ]; then
        [ ! -f "$log_file" ] && { echo "File not found: $log_file" >&2; exit 1; }
        log_content=$(tail -n "$lines" "$log_file")

    elif [ -n "$container" ]; then
        # Check if container exists
        if ! docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
            echo "Container not found: $container" >&2
            echo "Available containers:" >&2
            docker ps --format '  {{.Names}}' >&2
            exit 1
        fi

        # Build docker logs command
        local docker_cmd="docker logs"
        [ -n "$since" ] && docker_cmd="$docker_cmd --since $since"
        docker_cmd="$docker_cmd --tail $lines $container"

        log_content=$(eval "$docker_cmd" 2>&1)
        [ -z "$log_content" ] && { echo "No logs found for $container" >&2; exit 1; }

    else
        echo "Error: Specify a container, --file, or --stdin" >&2
        echo "Use --help for usage information" >&2
        exit 1
    fi

    # Run analysis
    # Use 32b by default for thorough analysis (logs benefit from deep reasoning)
    local result
    result=$(echo "$log_content" | "$WRAPPER" analyze_logs $quiet $model_arg)

    # Output result
    if [ -n "$output_file" ]; then
        echo "$result" > "$output_file"
        echo "Analysis saved to: $output_file" >&2
    else
        echo "$result"
    fi
}

main "$@"
