local sysdata = require("sysdata")
local system = require("system")
local registry = require("registry")
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
    local regModePath = sysmode.current().reg
    if regModePath and not registry.data.modeRegApply then
        registry.apply(regModePath)
        registry.data.modeRegApply = true
        registry.save()
    end
end

sysmode.unloadable = true
return sysmode