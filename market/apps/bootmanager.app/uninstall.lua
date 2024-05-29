local paths = require("paths")
local fs = require("filesystem")
local system = require("system")

fs.remove("/bootmanager")
fs.remove(paths.path(system.getSelfScriptPath()))