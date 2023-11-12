local fs = require("filesystem")
local paths = require("paths")

local sysdata = {}
sysdata.defaults = {
    ["branch"] = "main",
    ["mode"] = "full"
}

function sysdata.path(key)
    return paths.concat("/system/sysdata", key)
end

function sysdata.default(key)
    return sysdata.defaults[key]
end


function sysdata.get(key)
    local path = sysdata.path(key)
    if fs.exists(path) then
        return fs.readFile(path) or error("key not found", 2)
    else
        return sysdata.default(key) or error("key not found", 2)
    end
end

function sysdata.set(key, value)
    local path = sysdata.path(key)
    return fs.writeFile(path, value or sysdata.default(key))
end

function sysdata.update(key)
    local path = sysdata.path(key)
    if not fs.exists(path) then
        return sysdata.set(key)
    end
end

for key in pairs(sysdata.defaults) do
    sysdata.update(key)
end

sysdata.unloadable = true
return sysdata