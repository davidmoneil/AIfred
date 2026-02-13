#!/bin/bash
# fabric-wrapper.sh - Robust fabric execution with health check and model fallback
# Part of CLI capability layer
#
# Features:
#   - Ollama health check before execution
#   - Auto-restart Ollama if unresponsive
#   - Timeout with fallback to smaller model
#   - Streaming output support
#
# Usage:
#   echo "content" | fabric-wrapper.sh <pattern> [options]
#   fabric-wrapper.sh <pattern> --file <path> [options]
#
# Examples:
#   git diff | fabric-wrapper.sh summarize_git_diff
#   fabric-wrapper.sh analyze_logs --file /tmp/logs.txt
#   echo "code" | fabric-wrapper.sh review_code --model-only 7b

set -euo pipefail

# Configuration
FABRIC_BIN="${FABRIC_BIN:-$HOME/bin/fabric}"
OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434}"
PRIMARY_MODEL="${FABRIC_PRIMARY_MODEL:-qwen2.5:7b-instruct}"
FALLBACK_MODEL="${FABRIC_FALLBACK_MODEL:-qwen2.5:7b-instruct}"
TIMEOUT_PRIMARY="${FABRIC_TIMEOUT_PRIMARY:-120}"
TIMEOUT_FALLBACK="${FABRIC_TIMEOUT_FALLBACK:-180}"
HEALTH_CHECK_RETRIES=3
HEALTH_CHECK_WAIT=5

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging
log_info() { echo -e "${GREEN}[fabric]${NC} $1" >&2; }
log_warn() { echo -e "${YELLOW}[fabric]${NC} $1" >&2; }
log_error() { echo -e "${RED}[fabric]${NC} $1" >&2; }

# Show usage
usage() {
    cat << 'EOF'
Usage: fabric-wrapper.sh <pattern> [options]

Options:
  --file <path>       Read input from file instead of stdin
  --model-only <size> Force specific model: "32b" or "7b"
  --no-fallback       Don't fall back to smaller model on timeout
  --timeout <sec>     Custom timeout (default: 90s for 32b, 120s for 7b)
  --quiet             Suppress status messages
  --help              Show this help

Environment Variables:
  FABRIC_PRIMARY_MODEL    Primary model (default: qwen2.5:32b)
  FABRIC_FALLBACK_MODEL   Fallback model (default: qwen2.5:7b-instruct)
  FABRIC_TIMEOUT_PRIMARY  Primary timeout in seconds (default: 90)
  FABRIC_TIMEOUT_FALLBACK Fallback timeout in seconds (default: 120)

Examples:
  git diff --staged | fabric-wrapper.sh summarize_git_diff
  docker logs nginx | fabric-wrapper.sh analyze_logs
  fabric-wrapper.sh review_code --file src/main.ts
EOF
    exit 0
}

# Check if Ollama is responsive
check_ollama_health() {
    curl -s --max-time 5 "${OLLAMA_URL}/api/tags" >/dev/null 2>&1
}

# Restart Ollama service
restart_ollama() {
    log_warn "Attempting to restart Ollama..."

    # Try systemctl first (if running as service)
    if systemctl is-active --quiet ollama 2>/dev/null; then
        sudo systemctl restart ollama 2>/dev/null && return 0
    fi

    # Try docker restart
    if docker ps --format '{{.Names}}' | grep -q "^ollama$"; then
        docker restart ollama 2>/dev/null && return 0
    fi

    # Try killing and restarting process
    pkill -f "ollama serve" 2>/dev/null || true
    sleep 2
    nohup ollama serve >/dev/null 2>&1 &
    return 0
}

# Ensure Ollama is healthy, restart if needed
ensure_ollama() {
    local retries=$HEALTH_CHECK_RETRIES

    while [ $retries -gt 0 ]; do
        if check_ollama_health; then
            return 0
        fi

        log_warn "Ollama not responding (attempt $((HEALTH_CHECK_RETRIES - retries + 1))/$HEALTH_CHECK_RETRIES)"

        if [ $retries -eq $HEALTH_CHECK_RETRIES ]; then
            restart_ollama
        fi

        sleep $HEALTH_CHECK_WAIT
        retries=$((retries - 1))
    done

    log_error "Ollama failed to respond after $HEALTH_CHECK_RETRIES attempts"
    return 1
}

# Run fabric with timeout
run_fabric() {
    local model="$1"
    local timeout="$2"
    local pattern="$3"
    shift 3
    local extra_args=("$@")

    log_info "Running pattern '$pattern' with model '$model' (timeout: ${timeout}s)"

    # Use timeout command with fabric
    if timeout --signal=KILL "${timeout}s" "$FABRIC_BIN" \
        --pattern "$pattern" \
        --model "$model" \
        --stream \
        "${extra_args[@]}" 2>/dev/null; then
        return 0
    else
        local exit_code=$?
        if [ $exit_code -eq 137 ] || [ $exit_code -eq 124 ]; then
            log_warn "Timeout after ${timeout}s with model '$model'"
            return 124  # Timeout
        else
            log_warn "Failed with exit code $exit_code"
            return $exit_code
        fi
    fi
}

# Main execution
main() {
    local pattern=""
    local input_file=""
    local force_model=""
    local no_fallback=false
    local custom_timeout=""
    local quiet=false
    local extra_args=()

    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --help|-h)
                usage
                ;;
            --file)
                input_file="$2"
                shift 2
                ;;
            --model-only)
                case "$2" in
                    32b|32B) force_model="$PRIMARY_MODEL" ;;
                    7b|7B)   force_model="$FALLBACK_MODEL" ;;
                    *)       force_model="$2" ;;
                esac
                shift 2
                ;;
            --no-fallback)
                no_fallback=true
                shift
                ;;
            --timeout)
                custom_timeout="$2"
                shift 2
                ;;
            --quiet|-q)
                quiet=true
                shift
                ;;
            -*)
                extra_args+=("$1")
                shift
                ;;
            *)
                if [ -z "$pattern" ]; then
                    pattern="$1"
                else
                    extra_args+=("$1")
                fi
                shift
                ;;
        esac
    done

    # Validate pattern
    if [ -z "$pattern" ]; then
        log_error "No pattern specified"
        usage
    fi

    # Suppress logging if quiet
    if $quiet; then
        log_info() { :; }
        log_warn() { :; }
    fi

    # Read input
    local input=""
    if [ -n "$input_file" ]; then
        if [ ! -f "$input_file" ]; then
            log_error "File not found: $input_file"
            exit 1
        fi
        input=$(cat "$input_file")
    elif [ ! -t 0 ]; then
        input=$(cat)
    else
        log_error "No input provided (use --file or pipe content)"
        exit 1
    fi

    # Ensure Ollama is running
    if ! ensure_ollama; then
        log_error "Cannot connect to Ollama"
        exit 1
    fi

    # Determine models and timeouts
    local models=()
    local timeouts=()

    if [ -n "$force_model" ]; then
        models=("$force_model")
        timeouts=("${custom_timeout:-$TIMEOUT_FALLBACK}")
    elif $no_fallback; then
        models=("$PRIMARY_MODEL")
        timeouts=("${custom_timeout:-$TIMEOUT_PRIMARY}")
    else
        models=("$PRIMARY_MODEL" "$FALLBACK_MODEL")
        timeouts=("${custom_timeout:-$TIMEOUT_PRIMARY}" "${custom_timeout:-$TIMEOUT_FALLBACK}")
    fi

    # Try each model
    local i=0
    for model in "${models[@]}"; do
        local timeout="${timeouts[$i]}"

        if echo "$input" | run_fabric "$model" "$timeout" "$pattern" "${extra_args[@]}"; then
            exit 0
        fi

        local exit_code=$?
        if [ $exit_code -ne 124 ] && [ ${#models[@]} -eq 1 ]; then
            # Non-timeout error with single model
            exit $exit_code
        fi

        i=$((i + 1))
    done

    log_error "All models failed for pattern '$pattern'"
    exit 1
}

main "$@"
