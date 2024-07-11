_restrictedLoader = true
local invoke = component.invoke
local eeprom = component.proxy(component.list("eeprom")())
local func = load("return " .. eeprom.getData(), nil, nil, {})
local data = (func and func()) or {}

local function save()
    local str = "{"
    for k, v in pairs(data) do
        if type(v) == "string" then
            str = str .. k .. "='" .. v .. "',"
        else
            str = str .. k .. "=" .. tostring(v) .. ","
        end
    end
    pcall(eeprom.setData, str .. "}")
end

computer.setBootAddress = function(address)
    data.a = address
    save()
end

computer.getBootAddress = function()
    return data.a
end

do
    local screen = component.list("screen")()
    local gpu = component.list("gpu")()
    if gpu and screen then
        invoke(gpu, "bind", screen)
    end
end

local function checkSystem(address)
    return invoke(address, "exists", "/init.lua")
end

local addr = data.a or ""

if not component.proxy(addr) then
    error("restricted loader: the boot disk is missing", 0)
end

if not checkSystem(addr) then
    error("restricted loader: the system failed verification", 0)
end

invoke(computer.tmpAddress(), "makeDirectory", "bootloader") --blocks bootmanager startup
invoke(addr, "remove", "/bootmanager") --attempt to remove bootmanager. restricted loader runs only the verified operating systems
invoke(addr, "remove", "/vendor/apps/bootmanager.app")

local file = invoke(addr, "open", "/init.lua")
local buffer = ""
repeat
    local data = invoke(addr, "read", file, math.maxinteger or math.huge)
    buffer = buffer .. (data or "")
until not data
invoke(addr, "close", file)
assert(load(buffer, "=init"))()