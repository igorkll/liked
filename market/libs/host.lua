local computer = require("computer")
local bootloader = require("bootloader")
local unicode = require("unicode")
local natives = require("natives")
local time = require("time")
local host = {}

function host.deltaTime(checktime)
    local t1 = time.getRealTime() / 1000
    os.sleep(checktime or 1)
    local t2 = time.getRealTime() / 1000
    return (t2 - t1) / ((checktime or 1) * 20)
end

function host.tps(checktime)
    return 1 / host.deltaTime(checktime)
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