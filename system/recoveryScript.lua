local component = component or require("component")
local bootloader = bootloader or require("bootloader")

recoveryApi.menu("Liked Recovery Tool", {
    "Recovery From Internet"
}, {
    function ()
        if component.list("internet")() then
            local sysdata = "{data={"
            for _, file in ipairs(bootloader.bootfs.list("/system/sysdata")) do
                local fullpath = "/system/sysdata/" .. file
                sysdata = sysdata .. file .. "=" .. bootloader.readFile(fullpath) .. ","
            end
            sysdata = sysdata .. "}}"
            local content = "local installdata = " .. sysdata .. "\n" .. bootloader.readFile(bootloader.bootfs, "/system/likedlib/update/update.lua")
        else
            recoveryApi.info("An internet card is required")
        end 
    end
})