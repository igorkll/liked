local event = require("event")
local fs = require("filesystem")
local system = require("system")
local paths = require("paths")

fs.remove(paths.path(system.getSelfScriptPath()))

if _G.pistonBg then
    event.cancel(_G.pistonBg)
    _G.pistonBg = nil
end

if _G.pistonBg2 then
    event.cancel(_G.pistonBg2)
    _G.pistonBg2 = nil
end