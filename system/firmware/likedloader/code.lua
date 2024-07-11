_likedLoader = true
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
    _pcall(eeprom.setData, str .. "}")
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

local addr = data.a

for address in component.list("filesystem") do
    init, reason = tryLoadFrom(address)
    if init then
        computer.setBootAddress(address)
        break
    end
end

if not addr then
    error("liked loader: could not find a suitable OS to boot", 0)
end

invoke(computer.tmpAddress(), "makeDirectory", "bootloader") --blocks bootmanager startup

local file = invoke(addr, "open", "/init.lua")
local buffer = ""
repeat
    local data = invoke(addr, "read", file, math.maxinteger or math.huge)
    buffer = buffer .. (data or "")
until not data
invoke(addr, "close", file)
assert(load(buffer, "=init"))()