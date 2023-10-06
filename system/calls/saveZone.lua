local graphic = require("graphic")
local screen = ...
local rx, ry = graphic.getResolution(screen)
return screenshot(screen, rx / 2 - 15, ry / 2 - 3, 32, 8)