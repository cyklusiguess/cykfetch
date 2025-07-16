local red = "\27[31m"
local reset = "\27[0m"

local user = os.getenv("USER") or "Unknown"
local host = io.popen("hostname"):read("*l")
local os = "Unknown"
local kernel = "Unknown"

local os_file = io.open("/etc/os-release", "r")
if os_file then
    for line in os_file:lines() do
        if line:find("PRETTY_NAME") then
            local start = line:find('=') + 2
            local finish = line:reverse():find('"')
            if start and finish then
                os = line:sub(start, -finish - 1)
            end
            break
        end
    end
    os_file:close()
end

local kern_file = io.open("/proc/sys/kernel/osrelease", "r")
if kern_file then
    kernel = kern_file:read("*l")
    kern_file:close()
end

local uptime_seconds = 0
local uptime_file = io.open("/proc/uptime", "r")
if uptime_file then
    uptime_seconds = tonumber(uptime_file:read("*l"):match("^(%S+)"))
    uptime_file:close()
end
local uptime_hours = math.floor(uptime_seconds / 3600)
local uptime_minutes = math.floor((uptime_seconds / 60) % 60)
local uptime
if uptime_hours == 0 then
    uptime = string.format("%d minutes", uptime_minutes)
else
    uptime = string.format("%d hours, %d minutes", uptime_hours, uptime_minutes)
end

local pkgs = 0
local pkgs_file = io.popen("pacman -Qq | wc -l")
if pkgs_file then
    pkgs = tonumber(pkgs_file:read("*l"))
    pkgs_file:close()
end

local total, available = 0, 0
local meminfo_file = io.open("/proc/meminfo", "r")
if meminfo_file then
    for line in meminfo_file:lines() do
        if line:find("MemTotal") then
            total = tonumber(line:match("(%d+)")) / 1024
        elseif line:find("MemAvailable") then
            available = tonumber(line:match("(%d+)")) / 1024
        end
    end
    meminfo_file:close()
end
local mem_used = total - available

local cpu = "Unknown"
local cpu_file = io.open("/proc/cpuinfo", "r")
if cpu_file then
    for line in cpu_file:lines() do
        if line:find("model name") then
            cpu = line:match(": (.+)")
            break
        end
    end
    cpu_file:close()
end

local gpu = "unknown (will try to add amd support later)"
local gpu_file = io.open("/sys/class/drm/card0/device/driver/module", "r")
if gpu_file then
    gpu = gpu_file:read("*l")
    gpu_file:close()
    if gpu:find("nvidia") then
        gpu = "NVIDIA GPU"
    end
end

print(red)
print(string.format("       /\\       %s@%s", user, host))
print(string.format("      /  \\      os: %s", os))
print(string.format("     /\\   \\     kernel: %s", kernel))
print(string.format("    /      \\    uptime: %s", uptime))
print(string.format("   /   ,,   \\   packages: %d", pkgs))
print(string.format("  /   |  |  -   memory: %dM / %dM", mem_used, total))
print(string.format(" /_-''    ''-_\\ cpu: %s", cpu))
print(string.format("                gpu: %s", gpu))
print(reset)
