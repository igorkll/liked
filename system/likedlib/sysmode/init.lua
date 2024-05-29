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
    },
    demo = {
        reg = system.getResourcePath("demo.reg")
    }
}

function sysmode.current()
    return sysmode.modes[sysdata.get("mode")] or error("unknown current system mode", 2)
end

function sysmode.init()
    local smode = sysmode.current()

    local function apply(vtag, regPath)
        if regPath then
            local sdata = assert(serialization.load(regPath))
            if not registry[vtag] or registry[vtag] ~= sdata[vtag] then
                registry.apply(sdata)
                registry.save()
            end
        end
    end

    apply("sysmodeVersion", smode.reg)
    apply("modifierVersion", smode.modifier)

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