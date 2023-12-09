local computer = require("computer")
local gui = require("gui")
local fs = require("filesystem")
local warnings = {}

function warnings.list()
    local list = {}

    if computer.totalMemory() / 1024 < 512 then
        table.insert(list, "small amount of RAM on the device\nthis can lead to problems")
    end

    local rootfs = fs.get("/")
    if (rootfs.spaceTotal() - rootfs.spaceUsed()) / 1024 < 128 then
        table.insert(list, "not enough free disk space\nthis can lead to problems")
    end

    if fs.exists("/data/errorlog.log") then
        table.insert(list, "there were errors in your system, please check the \"errorlog\"")
    end

    return list
end

warnings.unloadable = true
return warnings