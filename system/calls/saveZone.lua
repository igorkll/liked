local graphic = require("graphic")
local screen = ...
local rx, ry = graphic.getResolution(screen)
return screenshot(screen, rx / 2 - 16, ry / 2 - 4, 33, 9)