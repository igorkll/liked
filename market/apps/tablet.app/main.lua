local uix = require("uix")
local gobjs = require("gobjs")

local screen = ...
local ui = uix.manager(screen)
local rx, ry = ui:zoneSize()

--------------------------------- layout 1

layout1 = ui:create("layout 1", uix.colors.black)
layout1:createText(2, ry - 3, uix.colors.white, "hold down the \"shift\" and hold the right mouse button on the object")
layout1:createText(2, ry - 2, uix.colors.white, "of study with the tablet in your hands until the beep sounds.")
layout1:createText(2, ry - 1, uix.colors.white, "if you hold down the mouse button too not long, the tablet will turn off")


---------------------------------

ui:loop()