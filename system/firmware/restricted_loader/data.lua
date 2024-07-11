local gui = require("gui")
local fs = require("filesystem")
local serialization = require("serialization")

local screen, _, hidden = ...
local retData = serialization.serialize({a = fs.bootaddress})

if hidden then
    return retData
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

if not gui.nextOrCancel(screen, nil, nil, "this thing is needed for extremely specific tasks, DO NOT INSTALL IT IF YOU DO NOT KNOW WHY YOU NEED IT") then
    return true
end

clear()

return retData