local component = component or require("component")
local bootloader = bootloader or require("bootloader")

recoveryApi.menu("Liked Recovery Tool", {
    "Recovery From Internet"
}, {
    function ()
        local internet = component.proxy(component.list("internet")() or "")
        if internet then
            local content = bootloader.readFile(bootloader.bootfs, "/system/likedlib/update/update.lua")
        end
    end
})