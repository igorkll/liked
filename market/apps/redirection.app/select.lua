local gui = require("gui")
local paths = require("paths")
local system = require("system")
local apps = require("apps")

local screen, nickname = ...
local folder = paths.path(system.getSelfScriptPath())

local levels = {}
for i = 0, 12 do
    table.insert(levels, "level " .. i)
end
local num = gui.select(screen, nil, nil, "select game level", levels)
if num then
    apps.execute(paths.concat(folder, "main.lua"), screen, nickname, num - 1)
end