local graphic = require("graphic")
local gui_container = require("gui_container")

local screen = ...
local mx, my = graphic.maxResolution(screen)

graphic.setDepth(screen, graphic.maxDepth(screen))
if mx > 80 or my > 25 then
    mx = 80
    my = 25
end
graphic.setResolution(screen, mx, my)

system_setTheme("/data/theme.plt")