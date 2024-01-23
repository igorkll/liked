local component = component or require("component")
local bootloader = bootloader or require("bootloader")
local computer = computer or require("computer")

local startupPath = "/likeOS_startup.lua"
local strs = {
    "Recovery From Internet",
    "Reset Settings (does not delete data)",
    "Start The System In Recovery Mode"
}
local funcs = {
    function (str)
        if component.list("internet")() then
            if recoveryApi.yesno(str) then
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
            end
        else
            recoveryApi.info("An internet card is required")
        end
    end,
    function (str)
        if recoveryApi.yesno(str) then
            bootloader.dofile("/system/liked/reset.lua", _ENV, bootloader.bootfs)
            recoveryApi.info("Settings Successfully Reset")
        end
    end,
    function ()
        if not require then
            recoveryApi.info({"Initializing The Kernel", "Please Wait"}, true)
            local result = "Successful Kernel Initialization"
            local ok, err = pcall(bootloader.bootstrap)
            if not ok then
                result = tostring(err or "Unknown Error")
            end
            recoveryApi.info(result)
        end

        bootloader.recoveryMode = true
        bootloader.runShell(bootloader.defaultShellPath)
    end
}

if bootloader.bootfs.exists(startupPath) then
    strs[1] = "Cancel Scheduled Recover"
    funcs[1] = function ()
        bootloader.bootfs.remove(startupPath)
        computer.shutdown("fast")
    end
end

recoveryApi.menu("Liked Recovery Tool", strs, funcs)