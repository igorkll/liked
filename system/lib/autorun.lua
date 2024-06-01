local registry = require("registry")
local fs = require("filesystem")
local programs = require("programs")
local logs = require("logs")
local cache = require("cache")
local autorun = {}

if not cache.static.aexec then
    function autorun.autorun()
        if registry.autorun then
            local function doAutorun(tbl)
                local needSave
                for i = #tbl, 1, -1 do
                    local path = tbl[i]
                    if path and fs.exists(path) then
                        logs.assert(programs.execute(path))
                    else
                        table.clear(tbl, path)
                        needSave = true
                    end
                end
                return needSave
            end

            local needSave
            if registry.autorun.system then
                needSave = doAutorun(registry.autorun.system)
            end
            if registry.autorun.user then
                if doAutorun(registry.autorun.user) then
                    needSave = true
                end
            end
            if needSave then
                registry.save()
            end
        end
        autorun.autorun = nil
        cache.static.aexec = true
    end
end

function autorun.reg(group, path, rm)
    if not registry.data.autorun then registry.data.autorun = {} end
    if not registry.data.autorun[group] then registry.data.autorun[group] = {} end
    table.clear(registry.data.autorun[group], path)
    if not rm then
        table.insert(registry.data.autorun[group], path)
    end
    registry.save()
end

autorun.unloadable = true
return autorun