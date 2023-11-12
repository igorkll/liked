local system = require("system")
local paths = require("paths")
local resources = {}

function resources.get(name)
    return paths.concat(paths.path(system.getSelfScriptPath()), name)
end

resources.unloadable = true
return resources