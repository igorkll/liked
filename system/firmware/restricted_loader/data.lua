local gui = require("gui")
local fs = require("filesystem")
local component = require("component")
local time = require("time")
local computer = require("computer")

local screen, _, hidden = ...
local appendData = "local bootAddress = \"" .. fs.bootaddress .. "\"\n"

local function apply()
    local eeprom = component.list("eeprom")()
    require("sysdata").set("eeprom", eeprom)
    component.invoke(eeprom, "makeReadonly", component.invoke(eeprom, "getChecksum"))
    component.invoke(eeprom, "setData", tostring(time.getRealTime()))
    computer.shutdown("fast")
end

if hidden then
    return nil, appendData, apply
end

local clear = gui.saveBigZone(screen)

if not gui.nextOrCancel(screen, nil, nil, "Attention 1!!! after installation, you will not be able to boot into other operating systems") then
    return true
end

if not gui.nextOrCancel(screen, nil, nil, "Attention 2!!! this loader verifies the authenticity of your OS for changes, it will not load the OS if changes are made to it") then
    return true
end

if not gui.nextOrCancel(screen, nil, nil, "Attention 3!!! with this loader, you will not be able to use bootmanager. bootmanager will simply be deleted from the computer if it has been installed") then
    return true
end

if not gui.nextOrCancel(screen, nil, nil, "Attention 4!!! this loader will not allow you to boot from other disks except from where it was installed") then
    return true
end

if not gui.nextOrCancel(screen, nil, nil, "Attention 5!!! you will not be able to use the system recovery menu after installation") then
    return true
end

if not gui.nextOrCancel(screen, nil, nil, "Attention 6!!! your operating system will no longer be able to boot using another EEPROM") then
    return true
end

if not gui.nextOrCancel(screen, nil, nil, "Attention 7!!! after installation, the EEPROM will automatically become readonly, it will be possible to remove \"Restricted Loader\" only by replacing the EEPROM and manually reinstalling the system from recovery(after replacing the EEPROM, the system cannot be started, but you will be able to open recovery)") then
    return true
end

if not gui.nextOrCancel(screen, nil, nil, "this thing is needed for extremely specific tasks, DO NOT INSTALL IT IF YOU DO NOT KNOW WHY YOU NEED IT") then
    return true
end

clear()
return nil, appendData, apply