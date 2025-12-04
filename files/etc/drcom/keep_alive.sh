#!/bin/sh

# 引入 OpenWrt 常用函数库
. /lib/functions.sh

CONFIG_FILE="/etc/drcom/config.yaml"
# 使用特殊的 tag 记录日志，方便 grep
LOG_TAG="drcom_keep_alive"

log() {
    # 写入系统日志，使用 logread 查看
    logger -t "$LOG_TAG" "$1"
}

# 健壮的 YAML 读取函数
read_yaml_key() {
    local key="$1"
    if [ -f "$CONFIG_FILE" ]; then
        grep "^[[:space:]]*${key}:" "$CONFIG_FILE" | sed -e "s/^.*${key}:[[:space:]]*//" -e 's/["\r'\'']//g'
    fi
}

# 读取必要配置
INTERVAL=$(read_yaml_key 'keep_alive_interval')
URL=$(read_yaml_key 'keep_alive_url')

# 设置默认值
INTERVAL=${INTERVAL:-300}
URL=${URL:-"http://www.baidu.com"}

log "Started. Checking $URL every $INTERVAL seconds."

# 启动初期等待 60 秒，给主程序和网络接口一点时间
sleep 60

while true; do
    # 使用 wget 仅检测连接 (--spider)，不下载文件
    # 超时时间设为 10 秒
    if ! wget -q --spider --timeout=10 "$URL"; then
        log "Network unreachable. URL: $URL"
        
        # 检查主程序是否还在运行
        if pgrep -x "drcom_client" > /dev/null; then
            log "Process exists but network is down. Killing process to trigger procd respawn..."
            
            # --- 核心修改 ---
            # 直接杀掉主进程。
            # 因为 init.d 里配置了 'procd_set_param respawn'，
            # procd 监控到进程消失后，会自动、干净地重新启动它。
            # 这样保活脚本自己可以继续运行，不会被中断。
            killall -9 drcom_client
            
            # 等待一会，给程序重启的时间，避免连续杀进程
            sleep 20
        else
            log "Process not running. Waiting for system to restart it..."
        fi
    else
        # 网络正常，静默通过
        :
    fi

    sleep "$INTERVAL"
done