local event = require("event")
local fs = require("filesystem")
local system = require("system")
local paths = require("paths")

_G.pistonCurrentSide = nil

if _G.pistonBg then
    for addr, id in pairs(_G.pistonBg) do
        event.cancel(id)
    end
    _G.pistonBg = nil
end

if _G.pistonBg2 then
    for addr, id in pairs(_G.pistonBg2) do
        event.cancel(id)
    end
    _G.pistonBg2 = nil
end

fs.remove(paths.path(system.getSelfScriptPath()))