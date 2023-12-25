local computer = require("computer")
local bootloader = require("bootloader")
local unicode = require("unicode")
local natives = require("natives")
local host = {}

function host.deltaTime()
    local t1 = computer.uptime()
    pcall(natives.computer.beep, 0)
    local t2 = computer.uptime()
    return t2 - t1
end

function host.tps()
    return 1 / host.deltaTime()
end

function host.worldFolder()
    local parser = require("parser")

    local invalidPath = "nonExistentFile/nonExistentFile"
    local fullInvalidPath = "opencomputers/" .. tostring(bootloader.bootfs.address) .. "/" .. invalidPath

    local file, err = bootloader.bootfs.open(invalidPath, "wb")
    if file then
        bootloader.bootfs.close(file)
    elseif type(err) == "string" then
        local path = parser.split(unicode, err, {fullInvalidPath, fullInvalidPath:gsub("/", "\\")})[1]
        if path and unicode.len(path) > 0 then
            return unicode.sub(path, 1, unicode.len(path) - 1)
        end
    end
end

host.unloadable = true
return host