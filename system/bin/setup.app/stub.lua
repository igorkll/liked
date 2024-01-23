local graphic = require("graphic")
local gui_contrainer = require("gui_contrainer")
local screen = ...

graphic.clear(screen, gui_contrainer.colors.cyan)
graphic.set(screen, 2, 2, gui_contrainer.colors.cyan, gui_contrainer.colors.white, "configuration expectations...")
graphic.forceUpdate(screen)