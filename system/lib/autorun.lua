local registry = require("registry")
local fs = require("filesystem")
local programs = require("programs")
local autorun = {}

function autorun.autorun()
    if registry.autorun then
        local function doAutorun(tbl)
            for _, path in ipairs(tbl) do
                if fs.exists(path) then
                    programs.execute(path)
                end
            end
        end

        if registry.autorun.system then
            doAutorun(registry.autorun.system)
        end

        if registry.autorun.user then
            doAutorun(registry.autorun.user)
        end
    end
    autorun.autorun = nil
end

autorun.unloadable = true
return autorun