local screen, _, hidden = ...

if hidden then
    return
end

local gui = require("gui")

if not gui.nextOrCancel(screen, nil, nil, "Attention 1!!! this loader does not allow you to load other operating systems except for liked") then
    return true
end

if not gui.nextOrCancel(screen, nil, nil, "Attention 2!!! this loader verifies the authenticity of your OS for changes, it will not load the OS if changes are made to it") then
    return true
end

if not gui.nextOrCancel(screen, nil, nil, "Attention 3!!! with this loader, you will not be able to use bootmanager") then
    return true
end

if not gui.nextOrCancel(screen, nil, nil, "Attention 4!!! this bootloader does not allow you to boot the OS from external disks") then
    return true
end

if not gui.nextOrCancel(screen, nil, nil, "this thing is needed for extremely specific tasks, DO NOT INSTALL IT IF YOU DO NOT KNOW WHY YOU NEED IT") then
    return true
end