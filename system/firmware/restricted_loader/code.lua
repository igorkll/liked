if not bootAddress then
    error("the address of the boot disk was not added to \"Restricted Loader\", it is incorrect to flash the EEPROM", 0)
end

_restrictedLoader = true
local invoke = component.invoke

computer.setBootAddress = function(address)
end

computer.getBootAddress = function()
    return bootAddress
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

if not component.proxy(bootAddress) then
    error("restricted loader: the boot disk is missing", 0)
end

if not checkSystem(bootAddress) then
    error("restricted loader: the system failed verification", 0)
end

invoke(computer.tmpAddress(), "makeDirectory", "bootloader") --blocks bootmanager startup
invoke(bootAddress, "remove", "/bootmanager") --attempt to remove bootmanager. restricted loader runs only the verified operating systems
invoke(bootAddress, "remove", "/vendor/apps/bootmanager.app")

local file = invoke(bootAddress, "open", "/init.lua")
local buffer = ""
repeat
    local data = invoke(bootAddress, "read", file, math.maxinteger or math.huge)
    buffer = buffer .. (data or "")
until not data
invoke(bootAddress, "close", file)
assert(load(buffer, "=init"))()