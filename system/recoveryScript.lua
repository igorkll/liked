local component = component or require("component")
local bootloader = bootloader or require("bootloader")
local computer = computer or require("computer")

local strs, funcs
local startupPath = "/likeOS_startup.lua"

if bootloader.bootfs.exists(startupPath) then
    strs = {
        "Cancel Scheduled Recover"
    }

    funcs = {
        function ()
            bootloader.bootfs.remove(startupPath)
            computer.shutdown("fast")
        end
    }
else
    strs = {
        "Recovery From Internet"
    }

    funcs = {
        function ()
            if component.list("internet")() then
                local sysdata = {branch = "main", mode = "full"}
                for _, file in ipairs(bootloader.bootfs.list("/system/sysdata") or {}) do
                    sysdata[file] = bootloader.readFile(bootloader.bootfs, "/system/sysdata/" .. file)
                end
    
                local sysdataStr = "{data={"
                for key, data in pairs(sysdata) do
                    sysdataStr = sysdataStr .. key .. "=\"" .. data .. "\","
                end
                sysdataStr = sysdataStr .. "}}"
    
                local content = "local installdata = " .. sysdataStr .. "\n" .. bootloader.readFile(bootloader.bootfs, "/system/likedlib/update/update.lua")
                if bootloader.writeFile(bootloader.bootfs, startupPath, content) then
                    computer.shutdown("fast")
                end
            else
                recoveryApi.info("An internet card is required")
            end 
        end
    }
end

recoveryApi.menu("Liked Recovery Tool", strs, funcs)