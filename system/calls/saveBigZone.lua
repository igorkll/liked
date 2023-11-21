local graphic = require("graphic")
local screen = ...
local cx, cy = graphic.getResolution(screen)
cx = cx / 2
cy = cy / 2
cx = cx - 25
cy = cy - 8
cx = math.round(cx) + 1
cy = math.round(cy) + 1
return graphic.screenshot(screen, cx, cy, 52, 17)