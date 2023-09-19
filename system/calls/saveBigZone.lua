local graphic = require("graphic")
local screen = ...
local rx, ry = graphic.getResolution(screen)
return screenshot(screen, math.round((rx / 2) - 25), math.round((ry / 2) - 8), 52, 17)