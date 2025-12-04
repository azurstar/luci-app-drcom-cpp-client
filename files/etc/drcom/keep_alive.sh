#!/bin/sh

. /lib/functions.sh

LOG_FILE="/tmp/drcom_client.log"

log() {
    local message
    message="$(date '+%Y-%m-%d %H:%M:%S') [drcom_keep_alive] $1"
    echo "$message" >> "$LOG_FILE"
}

# Simple YAML parser
get_config() {
    local key=$1
    local config_file="/etc/drcom/config.yaml"
    if [ -f "$config_file" ]; then
        # Ensure we read the file and handle potential empty results
        grep "^${key}:" "$config_file" | sed -e "s/^${key}: *//g" -e 's/"//g' | tr -d '\r'
    fi
}

log "Keep-alive script started."

# Read configuration
ENABLED=$(get_config 'keep_alive_enabled')
INTERVAL=$(get_config 'keep_alive_interval')
URL=$(get_config 'keep_alive_url')

log "Read config: keep_alive_enabled=${ENABLED}"

# Exit if not enabled
if [ "$ENABLED" != "true" ]; then
    log "Exiting: Keep-alive is not enabled in config."
    exit 0
fi

# Use default values if not set
INTERVAL=${INTERVAL:-300} # 300 seconds (5 minutes)
URL=${URL:-"http://www.baidu.com"}

log "Daemon configured. Checking connectivity every $INTERVAL seconds to $URL."

while true; do
    sleep "$INTERVAL"

    log "Performing connectivity check..."
    # Check connectivity
    if ! wget -q --spider --timeout=10 "$URL"; then
        log "Connectivity check failed. URL: $URL"
        # Check if service is actually running using procd
        local is_running
        service_running drcom_client && is_running=1 || is_running=0

        if [ "$is_running" -eq 1 ]; then
            log "Service is running, attempting to restart drcom_client service..."
            /etc/init.d/drcom_client restart &
        else
            log "Service is not running. Won't restart."
        fi
    else
        log "Connectivity check OK."
    fi
done
