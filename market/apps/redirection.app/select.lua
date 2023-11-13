local gui = require("gui")
local paths = require("paths")
local system = require("system")
local liked = require("liked")

local screen, nickname = ...
local folder = paths.path(system.getSelfScriptPath())

local levels = {}
for i = 0, 12 do
    table.insert(levels, "level " .. i)
end
local num = gui.select(screen, nil, nil, "select game level", levels)
if num then
    liked.execute(paths.concat(folder, "main.lua"), screen, nickname, num - 1)
end