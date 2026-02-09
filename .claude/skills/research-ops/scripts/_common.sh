#!/usr/bin/env bash
# research-ops shared utilities — credential extraction, error handling, output formatting
# Source this from all backend scripts: source "$SCRIPT_DIR/_common.sh"

CRED_FILE="/Users/aircannon/Claude/Jarvis/.claude/secrets/credentials.yaml"

# Extract credential from credentials.yaml
# Usage: KEY=$(get_credential ".search.brave")
get_credential() {
    local key_path="$1"
    if [[ ! -f "$CRED_FILE" ]]; then
        echo "ERROR: Credential file not found: $CRED_FILE" >&2
        return 1
    fi
    local value
    value=$(yq -r "$key_path" "$CRED_FILE" 2>/dev/null | head -1 | tr -d '[:space:]')
    if [[ -z "$value" || "$value" == "null" ]]; then
        echo "ERROR: No credential at path: $key_path" >&2
        return 1
    fi
    echo "$value"
}

# Report error with backend context
# Usage: handle_error "brave" "Rate limit exceeded" "429"
handle_error() {
    local backend="$1" message="$2" http_code="${3:-}"
    if [[ -n "$http_code" ]]; then
        echo "ERROR [$backend] HTTP $http_code: $message" >&2
    else
        echo "ERROR [$backend]: $message" >&2
    fi
    return 1
}

# Pretty-print JSON (passthrough on failure)
format_json() {
    if [[ -n "${1:-}" ]]; then
        echo "$1" | jq '.' 2>/dev/null || echo "$1"
    else
        jq '.' 2>/dev/null || cat
    fi
}

# URL-encode a string (bash 3.2 compatible)
url_encode() {
    local string="$1" encoded="" i c
    for (( i=0; i<${#string}; i++ )); do
        c="${string:$i:1}"
        case "$c" in
            [a-zA-Z0-9.~_-]) encoded+="$c" ;;
            ' ') encoded+='+' ;;
            *) encoded+=$(printf '%%%02X' "'$c") ;;
        esac
    done
    echo "$encoded"
}

# Validate required commands exist
require_commands() {
    local missing=0
    for cmd in "$@"; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "ERROR: Required command not found: $cmd" >&2
            missing=1
        fi
    done
    return $missing
}

# Make HTTP request with error checking
# Usage: http_get "https://api.example.com/search" [timeout_seconds]
http_get() {
    local url="$1" timeout="${2:-15}"
    local response http_code
    response=$(curl -s --compressed -w "\n%{http_code}" --max-time "$timeout" "$url" 2>/dev/null) || {
        echo "ERROR: curl failed for $url" >&2
        return 1
    }
    http_code=$(echo "$response" | tail -1)
    response=$(echo "$response" | sed '$d')
    if [[ "$http_code" -ge 400 ]] 2>/dev/null; then
        echo "ERROR: HTTP $http_code from $url" >&2
        echo "$response" >&2
        return 1
    fi
    echo "$response"
}

# Make HTTP POST request with JSON body
# Usage: http_post "https://api.example.com" '{"key":"val"}' "Header: value" [timeout]
http_post() {
    local url="$1" body="$2" header="${3:-}" timeout="${4:-15}"
    local curl_args=(-s --compressed -w "\n%{http_code}" --max-time "$timeout" -X POST -H "Content-Type: application/json")
    if [[ -n "$header" ]]; then
        curl_args+=(-H "$header")
    fi
    curl_args+=(-d "$body" "$url")
    local response http_code
    response=$(curl "${curl_args[@]}" 2>/dev/null) || {
        echo "ERROR: curl POST failed for $url" >&2
        return 1
    }
    http_code=$(echo "$response" | tail -1)
    response=$(echo "$response" | sed '$d')
    if [[ "$http_code" -ge 400 ]] 2>/dev/null; then
        echo "ERROR: HTTP $http_code from $url" >&2
        echo "$response" >&2
        return 1
    fi
    echo "$response"
}
