local uix = require("uix")

local screen = ...
local ui = uix.manager(screen)
local rx, ry = ui:zoneSize()

local layout = ui:create("controller [RC Control]", uix.colors.black)
layout:createText(ry - 2, 2, uix.colors.white, "to use, flash the EEPROM of the robot/drone with the \"RC Control\" firmware through the settings>eeprom")

layout.button1 = layout:createButton(2, 2, 16, 1, uix.colors.white, uix.colors.red, "BEEP")
function layout.button1:onClick()
    sound.beep(2000)
end
function layout.button1:onDrop()
    sound.beep(1000)
end

layout.button2 = layout:createButton(2, 4, 16, 1, uix.colors.white, uix.colors.red, "layout 2", true)
function layout.button2:onClick()
    ui:select(layout2)
end

ui:loop()