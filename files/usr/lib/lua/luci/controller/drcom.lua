module("luci.controller.drcom", package.seeall)
local fs = require "nixio.fs"
local http = require "luci.http"
local config_file = "/etc/drcom/config.yaml"
local init_script = "/etc/init.d/drcom_client"
local rc_script_path = "/etc/rc.d/S99drcom_client"
-- Helper to parse the simple YAML
local function parse_simple_yaml(content)
    local data = {}
    for line in content:gmatch("[^\r\n]+") do
        -- Strip comments first
        line = line:match("([^#]*)") or line
        line = line:match("^%s*(.-)%s*$")
        if line ~= "" then
            local key, val = line:match([=[^(%S+):%s*"(.*)"%s*$]=])
            if not key then
                key, val = line:match([=[^(%S+):%s*(.*)%s*$]=])
            end
            if key and val then
                val = val:gsub([=[^"(.*)"$]=], "%1")
                val = val:gsub([=[^'(.*)'$]=], "%1")
                -- Trim whitespace from the final value
                data[key] = val:match("^%s*(.-)%s*$")
            end
        end
    end
    return data
end
-- Helper to build the simple YAML
local function build_simple_yaml(tbl)
    local lines = {}
    local ordered_keys = {
        "server", "username", "password", "host_name", "host_os", "host_ip",
        "PRIMARY_DNS", "dhcp_server", "mac", "CONTROLCHECKSTATUS", "ADAPTERNUM",
        "KEEP_ALIVE_VERSION", "AUTH_VERSION", "IPDOG", "ror_version", "nic_name",
        "IS_TEST", "DEBUG", "LOG_PATH", "keep_alive_enabled", "keep_alive_interval",
        "keep_alive_test_ip"
    }
    for _, k in ipairs(ordered_keys) do
        local v = tbl[k]
        if v ~= nil then
            if type(v) == "boolean" then
                v = tostring(v)
            end
            table.insert(lines, string.format('%s: "%s"', k, v))
        end
    end
    return table.concat(lines, "\n") .. "\n"
end
-- Check if the drcom_client process is running
local function get_service_status()
    local handle = io.popen("pgrep drcom_client")
    if handle then
        local pid = handle:read("*l")
        handle:close()
        if pid and pid ~= "" then
            return true, "运行中 (PID: " .. pid .. ")"
        end
    end
    return false, "未运行"
end
-- Check if the service is enabled on boot
local function get_service_enabled_status()
    if fs.access(rc_script_path) then
        return true
    end
    return false
end
-- Read the config file and return a data table
local function get_config_data()
    local content = fs.readfile(config_file) or ""
    return parse_simple_yaml(content)
end
function index()
    entry({"admin", "services", "drcom"}, alias("admin", "services", "drcom", "status"), _("Drcom 客户端"), 60)
    entry({"admin", "services", "drcom", "status"}, call("page_status"), _("服务状态"), 1)
    entry({"admin", "services", "drcom", "config"}, call("page_config"), _("基础配置"), 2)
    entry({"admin", "services", "drcom", "advance"}, call("page_advance"), _("高级配置"), 3)
    entry({"admin", "services", "drcom", "log"}, call("page_log"), _("日志"), 4)
    -- Actions (no UI)
    entry({"admin", "services", "drcom", "save"}, call("action_save"), nil)
    entry({"admin", "services", "drcom", "start"}, call("action_start"), nil)
    entry({"admin", "services", "drcom", "stop"}, call("action_stop"), nil)
    entry({"admin", "services", "drcom", "restart"}, call("action_restart"), nil)
    entry({"admin", "services", "drcom", "toggle_boot"}, call("action_toggle_boot"), nil)
    entry({"admin", "services", "drcom", "clear_log"}, call("action_clear_log"), nil)
end
-- Force a unique redirect to defeat any caching
local function force_redirect()
    local url = luci.dispatcher.build_url("admin", "services", "drcom", "status")
    http.redirect(url .. "?rand=" .. math.random(10000))
end
-- Render status page
function page_status()
    -- Set no-cache headers to ensure the status is always live
    http.header("Cache-Control", "no-cache, no-store, must-revalidate")
    http.header("Pragma", "no-cache")
    http.header("Expires", "0")
    local running, running_str = get_service_status()
    local enabled = get_service_enabled_status()
    local data = {
        running = running,
        running_str = running_str,
        enabled = enabled,
        enabled_str = enabled and "开机自启" or "开机禁用"
    }
    http.prepare_content("text/html")
    luci.template.render("drcom/status", { data = data })
end
-- Render config page
function page_config()
    http.prepare_content("text/html")
    luci.template.render("drcom/config", { data = get_config_data() })
end
-- Render advance page
function page_advance()
    http.prepare_content("text/html")
    luci.template.render("drcom/advance", { data = get_config_data() })
end
-- Render log page
function page_log()
    local log_content = fs.readfile("/tmp/drcom_client.log") or "暂时没有日志可查看"
    http.prepare_content("text/html")
    luci.template.render("drcom/log", { log_content = log_content })
end
-- Save form data
function action_save()
    local form_data = {
        server = http.formvalue("server"),
        username = http.formvalue("username"),
        password = http.formvalue("password"),
        host_name = http.formvalue("host_name"),
        host_os = http.formvalue("host_os"),
        host_ip = http.formvalue("host_ip"),
        PRIMARY_DNS = http.formvalue("PRIMARY_DNS"),
        dhcp_server = http.formvalue("dhcp_server"),
        mac = http.formvalue("mac"),
        CONTROLCHECKSTATUS = http.formvalue("CONTROLCHECKSTATUS"),
        ADAPTERNUM = http.formvalue("ADAPTERNUM"),
        KEEP_ALIVE_VERSION = http.formvalue("KEEP_ALIVE_VERSION"),
        AUTH_VERSION = http.formvalue("AUTH_VERSION"),
        IPDOG = http.formvalue("IPDOG"),
        nic_name = http.formvalue("nic_name"),
        LOG_PATH = http.formvalue("LOG_PATH"),
        keep_alive_interval = http.formvalue("keep_alive_interval"),
        keep_alive_test_ip = http.formvalue("keep_alive_test_ip"),
        ror_version = http.formvalue("ror_version") == "1",
        IS_TEST = http.formvalue("IS_TEST") == "1",
        DEBUG = http.formvalue("DEBUG") == "1",
        keep_alive_enabled = http.formvalue("keep_alive_enabled") == "1"
    }

    local current_data = get_config_data()
    for k, v in pairs(form_data) do
        if v ~= nil then
            current_data[k] = v
        end
    end
    fs.writefile(config_file, build_simple_yaml(current_data))
    -- Redirect back to the page the user was on
    local origin = http.formvalue("origin") or ""
    local url = luci.dispatcher.build_url("admin", "services", "drcom", origin)
    http.redirect(url .. "?rand=" .. math.random(10000))
end
-- Service control actions
function action_start()
    os.execute("( " .. init_script .. " start ) &")
    force_redirect()
end

function action_stop()
    os.execute("( " .. init_script .. " stop ) &")
    force_redirect()
end

function action_restart()
    os.execute("( " .. init_script .. " restart ) &")
    force_redirect()
end
-- Toggle enable/disable on boot
function action_toggle_boot()
    local enabled = get_service_enabled_status()
    if enabled then
        os.execute("( " .. init_script .. " disable ) &")
    else
        os.execute("( " .. init_script .. " enable ) &")
    end
    force_redirect()
end
function action_clear_log()
    fs.writefile("/tmp/drcom_client.log", "")
    local url = luci.dispatcher.build_url("admin", "services", "drcom", "log")
    http.redirect(url .. "?rand=" .. math.random(10000))
end

