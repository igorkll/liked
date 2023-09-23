local event = require("event")
local fs = require("filesystem")
local system = require("system")
local paths = require("paths")

fs.remove(paths.path(system.getSelfScriptPath()))

if _G.magnetBg then
    event.cancel(_G.magnetBg)
    _G.magnetBg = nil
end