module("luci.controller.drcom", package.seeall)

-- 解析简单 YAML 文件内容的函数
local function parse_simple_yaml(content)
    local data = {}
    for line in content:gmatch("[^\r\n]+") do
        line = line:match("^%s*(.-)%s*$")       -- 去除首尾空白
        if line ~= "" and not line:match("^#") then  -- 跳过空行和注释
            local key, val = line:match('^(%S+):%s*"(.*)"%s*$')  -- 匹配带引号的值
            if not key then
                key, val = line:match('^(%S+):%s*(.*)%s*$')      -- 匹配不带引号的值
            end
            if key and val then
                val = val:gsub('^"(.*)"$', "%1")  -- 去掉值的引号
                data[key] = val
            end
        end
    end
    return data
end

-- 生成简单 YAML 文件内容的函数
local function build_simple_yaml(tbl)
    local lines = {}
    for k, v in pairs(tbl) do
        table.insert(lines, string.format('%s: "%s"', k, v))
    end
    return table.concat(lines, "\n")
end

-- 检查 drcom_client 的运行状态
local function check_drcom_status()
    local handle = io.popen("pgrep drcom_client")
    if handle then
        local pid = handle:read("*l")
        handle:close()
        if pid and pid ~= "" then
            return "运行中 (PID: " .. pid .. ")"
        end
    end
    return "未运行"
end

-- 查看日志内容
local function log_view()
    local fs = require "nixio.fs"
    local log_file = "/tmp/drcom_client.log"
    return fs.readfile(log_file) or "暂时没有日志可查看"
end

function index()
    -- 设定 Drcom 在菜单中的位置
    -- 第一个 entry() 用 alias() 将点击“Drcom”时默认跳转到“配置”页
    entry({"admin", "services", "drcom"}, alias("admin", "services", "drcom", "config"), _("Drcom 客户端"), 60)
    
    -- 注册“配置”页面
    entry({"admin", "services", "drcom", "config"}, call("config_page"), _("配置"), 1)
    
    -- 注册“日志”页面
    entry({"admin", "services", "drcom", "log"}, call("advance_page"), _("高级"), 2)
    
    -- 注册“高级”页面
    entry({"admin", "services", "drcom", "advance"}, call("log_page"), _("日志"), 3)

    -- 保存表单的处理函数
    entry({"admin", "services", "drcom", "save"}, call("config_save"), nil)
end

-- 配置页面
function config_page()
    local luci_http = require "luci.http"
    local fs = require "nixio.fs"
    
    -- 读取配置文件
    local config_file = "/etc/drcom/config.yaml"
    local content = fs.readfile(config_file) or ""
    local data = parse_simple_yaml(content)
    data.__status = check_drcom_status()

    -- 渲染配置页面
    luci_http.prepare_content("text/html")
    luci_http.write(luci.template.render("drcom/config", { data = data }))
end

-- 高级页面
function advance_page()
    local luci_http = require "luci.http"
    local fs = require "nixio.fs"
    
    -- 读取配置文件
    local config_file = "/etc/drcom/config.yaml"
    local content = fs.readfile(config_file) or ""
    local data = parse_simple_yaml(content)
    data.__status = check_drcom_status()

    -- 渲染配置页面
    luci_http.prepare_content("text/html")
    luci_http.write(luci.template.render("drcom/advance", { data = data }))
end

-- 日志页面
function log_page()
    local luci_http = require "luci.http"
    local log_content = log_view()

    -- 渲染日志页面
    luci_http.prepare_content("text/html")
    luci_http.write(luci.template.render("drcom/log", { log_content = log_content }))
end

-- 处理表单提交并保存配置
function config_save()
    local luci_http = require "luci.http"
    local fs = require "nixio.fs"
    local config_file = "/etc/drcom/config.yaml"

    -- 从表单获取字段值
    local formData = {
        server              = luci_http.formvalue("server") or "192.168.100.150",
        username            = luci_http.formvalue("username") or "",
        password            = luci_http.formvalue("password") or "",
        host_name           = luci_http.formvalue("host_name") or "Linux",
        host_os             = luci_http.formvalue("host_os") or "Linux",
        host_ip             = luci_http.formvalue("host_ip") or "0.0.0.0",
        PRIMARY_DNS         = luci_http.formvalue("PRIMARY_DNS") or "114.114.114.114",
        dhcp_server         = luci_http.formvalue("dhcp_server") or "0.0.0.0",
        mac                 = luci_http.formvalue("mac") or "b888e3051680",
        CONTROLCHECKSTATUS  = luci_http.formvalue("CONTROLCHECKSTATUS") or "20",
        ADAPTERNUM          = luci_http.formvalue("ADAPTERNUM") or "01",
        KEEP_ALIVE_VERSION  = luci_http.formvalue("KEEP_ALIVE_VERSION") or "dc02",
        AUTH_VERSION        = luci_http.formvalue("AUTH_VERSION") or "0a00",
        IPDOG               = luci_http.formvalue("IPDOG") or "01",
        ror_version         = luci_http.formvalue("ror_version") or "false",
        nic_name            = luci_http.formvalue("nic_name") or "",
        IS_TEST             = luci_http.formvalue("IS_TEST") or "true",
        DEBUG               = luci_http.formvalue("DEBUG") or "true",
        LOG_PATH            = luci_http.formvalue("LOG_PATH") or "/tmp/drcom_client.log",
    }

    -- 生成新的 YAML 文件内容
    local newYaml = build_simple_yaml(formData)
    fs.writefile(config_file, newYaml)

    -- 保存后重定向回“配置”页面
    luci_http.redirect(luci.dispatcher.build_url("admin", "services", "drcom", "config"))
end

