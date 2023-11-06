local gui = require("gui")
local programs = require("programs")
local paths = require("paths")
local system = require("system")

local screen, nickname = ...
local folder = paths.path(system.getSelfScriptPath())

local levels = {}
for i = 0, 12 do
    table.insert(levels, "level " .. i)
end
local num = gui.select(screen, nil, nil, "select game level", levels)
if num then
    programs.execute(paths.concat(folder, "main.lua"), screen, nickname, num - 1)
end