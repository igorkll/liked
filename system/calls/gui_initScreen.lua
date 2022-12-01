local graphic = require("graphic")
local calls = require("calls")
local gui_container = require("gui_container")

local screen = ...

graphic.setDepth(screen, graphic.maxDepth(screen))
graphic.setResolution(screen, graphic.maxResolution(screen))

system_setTheme("/data/theme.plt")