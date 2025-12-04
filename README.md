# OpenWRT Drcom 客户端

## 主要功能

- **图形化配置**: 提供完整的 Web 操作界面，用于配置 Dr.COM 客户端的各项参数。
- **服务状态监控**: 实时查看服务的运行状态、PID 等信息。
- **服务控制**: 支持通过界面对服务进行启动、停止和重启操作。
- **开机自启管理**: 方便地启用或禁用服务的开机自启功能。
- **在线日志查看**: 直接在网页上查看客户端的实时运行日志，便于快速诊断问题。
- **网络连接保持 (Keep-Alive)**: 内置独立的守护进程，定期检查网络连通性。如果发现网络断开，将自动重启客户端，确保网络连接的稳定性。

## 编译

1.  **获取源码并放置到 OpenWrt 源码目录**:
    ```bash
    git clone https://github.com/azurstar/luci-app-drcom-cpp-client package/luci-app-drcom-cpp-client
    ```

2.  **更新子模块**:
    ```bash
    cd package/luci-app-drcom-cpp-client
    git submodule update --init --recursive --remote
    cd ../..
    ```

3.  **配置菜单**:
    运行 `make menuconfig`，然后在 LuCI -> 3. Applications 中找到并选中 `luci-app-drcom-cpp-client`。

4.  **执行编译**:
    ```bash
    make V=s package/luci-app-drcom-cpp-client/compile -j$(nproc)
    ```
    编译完成后，生成的 `.ipk` 安装包位于 `bin/packages/<your_target_architecture>/luci/` 目录下。

## 安装

将编译好的 `.ipk` 文件上传到您的 OpenWrt 设备，然后通过 `opkg` 命令进行安装：

```bash
opkg install luci-app-drcom-cpp-client_*.ipk
```

## 使用说明

安装完成后，刷新 LuCI 页面，在 "服务" 菜单下即可找到 "Drcom 客户端" 的管理入口。

- **服务状态**:
  - 显示客户端是否正在运行、PID 以及开机自启状态。
  - 提供 "启动"、"停止"、"重启" 等控制按钮。
  - 提供 "启用自启"/"禁用自启" 的切换按钮。

- **基础配置 / 高级配置**:
  - 在这些页面中可以修改 `drcom-cpp-client` 的所有配置参数。
  - 提交保存后，配置将写入设备的 `/etc/drcom/config.yaml` 文件，并根据需要重启服务。

- **日志**:
  - 此页面会显示 `/tmp/drcom_client.log` 文件的内容。
  - `drcom-cpp-client` 主程序和网络连接保持脚本的日志都会输出到这里。
  - 点击 "清空日志" 按钮可以清空当前的日志文件。

## 故障排查

1.  **首要步骤**: 检查 "日志" 页面。大部分常见问题，如用户名密码错误、服务器地址错误等，都会在这里显示相关日志。
2.  **网络保持功能**: 如果网络断线后没有自动重连，可以检查 "高级配置" 中的 "启用网络连接保持" 是否已勾选，并查看日志中是否有 `[drcom_keep_alive]` 字样的条目。
3.  **服务无法启动/UI卡顿**: 如果在 LuCI 界面操作（如启动、停止）时遇到 "Bad Gateway" 错误或长时间无响应，可能是 `procd` 服务管理脚本存在问题。请确保使用了最新版本的代码。
4.  **系统日志**: 对于更深层次的问题，可以通过 SSH 登录到 OpenWrt 设备，使用 `logread` 命令查看系统日志，可能会有 `procd` 或内核相关的错误信息。
    ```bash
    logread | grep drcom
    ```
5.  **配置文件**: 客户端的最终配置文件位于 `/etc/drcom/config.yaml`，可以检查此文件内容是否与您在网页上设置的相符。
