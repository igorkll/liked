local computer = require("computer")
local bootloader = require("bootloader")
local unicode = require("unicode")
local host = {}

function host.deltaTime()
    local delta
    local t1 = computer.uptime()
    repeat
        pcall(computer.beep, 0)
        local t2 = computer.uptime()
        delta = t2 - t1
    until delta ~= 0
    return delta
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