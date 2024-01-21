local uix = require("uix")
local gobjs = require("gobjs")

local screen = ...
local ui = uix.manager(screen)
local rx, ry = ui:zoneSize()

--------------------------------- layout 1

layout1 = ui:create("layout 1", uix.colors.black)
layout1:createText(2, )

layout1.button1 = layout1:createButton(2, 2, 16, 1, uix.colors.white, uix.colors.red, "BEEP")


---------------------------------

ui:loop()