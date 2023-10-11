local graphic = require("graphic")
local system = require("system")
local paths = require("paths")
local gui = require("gui")

local hologramsPath = paths.concat(paths.path(system.getSelfScriptPath()), "holograms")

local screen = ...
local rx, ry = graphic.getResolution(screen)
local window = graphic.createWindow(screen, 1, 1, rx, ry)

local holo = gui.selectcomponent(screen, nil, nil, {"hologram"}, true)
