local sysdata = require("sysdata")
local system = require("system")
local registry = require("registry")
local serialization = require("serialization")
local fs = require("filesystem")

local sysmode = {}
sysmode.modes = {
    full = {
        reg = system.getResourcePath("full.reg")
    },
    classic = {
        reg = system.getResourcePath("classic.reg")
    }
}

function sysmode.current()
    return sysmode.modes[sysdata.get("mode")] or error("unknown current system mode", 2)
end

function sysmode.init()
    local smode = sysmode.current()
    if smode.reg then
        local sdata = assert(serialization.load(smode.reg))
        if not registry.sysmodeVersion or registry.sysmodeVersion ~= sdata.sysmodeVersion then
            registry.apply(sdata)
            registry.save()
        end
    end

    if registry.filesBlackList then
        for _, path in ipairs(registry.filesBlackList) do
            if fs.exists(path) then
                fs.remove(path)
            end
        end
    end
end

sysmode.unloadable = true
return sysmode