#!/bin/sh
. /lib/functions.sh

# Simple YAML parser
get_config() {
    local key=$1
    local config_file="/etc/drcom/config.yaml"
    if [ -f "$config_file" ]; then
        grep "^${key}:" "$config_file" | sed -e "s/^${key}: *//g" -e 's/"//g' | tr -d '\r'
    fi
}

LOG_FILE=$(get_config 'LOG_PATH')

log() {
    local message
    message="$(date '+%Y-%m-%d %H:%M:%S') [drcom_keep_alive] $1"
    echo "$message" >> "$LOG_FILE"
}

log "Keep-alive script started."

# Read configuration
ENABLED=$(get_config 'keep_alive_enabled')
INTERVAL=$(get_config 'keep_alive_interval')
TEST_IP=$(get_config 'keep_alive_test_ip')

log "Read config: keep_alive_enabled=${ENABLED}"

# Exit if not enabled
if [ "$ENABLED" != "true" ]; then
    log "Exiting: Keep-alive is not enabled in config."
    exit 0
fi

# Use default values if not set
INTERVAL=${INTERVAL:-60} # 建议改短一点，比如 60秒
log "Daemon configured. Checking connectivity every $INTERVAL seconds to $TEST_IP."

# 增加一个失败计数器，防止偶尔的丢包导致重启
FAIL_COUNT=0
MAX_FAIL=5

while true; do
    sleep "$INTERVAL"
    
    # 使用 Ping 检测 IP，-c 1 (1次), -W 3 (3秒超时)
    # 223.5.5.5 是阿里的 DNS，非常稳定
    if ping -c 1 -W 3 "$TEST_IP" > /dev/null 2>&1; then
        # 网络正常
        if [ "$FAIL_COUNT" -gt 0 ]; then
            log "Connectivity recovered. Resetting fail count."
        fi
        FAIL_COUNT=0
    else
        # 网络异常
        FAIL_COUNT=$((FAIL_COUNT + 1))
        log "Connectivity check failed ($FAIL_COUNT/$MAX_FAIL)."
        
        if [ "$FAIL_COUNT" -ge "$MAX_FAIL" ]; then
            log "Max failures reached. Restarting drcom_client service..."
            
            # 不管服务是不是在运行，直接重启/启动
            /etc/init.d/drcom_client restart
            
            # 重启后重置计数器，并多等待一会儿给服务启动时间
            FAIL_COUNT=0
            sleep 10
        fi
    fi
done