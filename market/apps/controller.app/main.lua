local uix = require("uix")

local screen = ...
local ui = uix.manager(screen)
local rx, ry = ui:zoneSize()

----------------------------- ui

layout = ui:create("controller [RC Control]", uix.colors.black)

infoLayout = ui:create("controller [INFO]", uix.colors.black)
infoLayout:createText(1, ry, uix.colors.white, "to use, flash the EEPROM of the robot/drone with the \"RC Control\" firmware through the settings>eeprom")
layout:setReturnLayout(infoLayout, uix.colors.green, " INFO ")

ui:loop()