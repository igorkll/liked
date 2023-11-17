local graphic = require("graphic")
local screen = ...
local cx, cy = graphic.getResolution(screen)
cx = cx / 2
cy = cy / 2
cx = cx - 16
cy = cy - 4
cx = math.round(cx) + 1
cy = math.round(cy) + 1
return graphic.screenshot(screen, cx, cy, 32, 8)