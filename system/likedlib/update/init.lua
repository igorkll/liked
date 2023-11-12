local paths = require("paths")
local system = require("system")
local fs = require("filesystem")
local computer = require("computer")
local serialization = require("serialization")
local sysdata = require("sysdata")
local update = {}
update.updaterPath = paths.concat(paths.path(system.getSelfScriptPath()), "update.lua")

function update._generate(data)
    local updater = assert(fs.readFile(update.updaterPath))
    local strdata = serialization.serialize(data)
    return "local installdata = " .. strdata .. "\n" .. updater
end

function update._write(data)
    assert(fs.writeFile("/likeOS_startup.lua", update._generate(data)))
end

function update.run(branch, mode)
    local data = {}
    data.branch = branch or sysdata.get("branch")
    data.mode = mode or sysdata.get("mode")
    
    update._write({data = data})
    computer.shutdown("fast")
end

update.unloadable = true
return update