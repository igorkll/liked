local graphic = require("graphic")
local screen = ...
local rx, ry = graphic.getResolution(screen)
return screenshot(screen, math.round((rx / 2) - 25) + 1, math.round((ry / 2) - 8) + 1, 50, 16)