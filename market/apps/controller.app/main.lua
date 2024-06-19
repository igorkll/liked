local uix = require("uix")
local gui_container = require("gui_container")

local screen = ...
local ui = uix.manager(screen)
local rx, ry = ui:zoneSize()

----------------------------- ui

layout = ui:create("controller [RC Control]", uix.colors.black)

infoLayout = ui:create("controller [INFO]", uix.colors.black)
infoLayout:createText(2, 2, uix.colors.white, gui_container.chars.dot .. " to use, flash the EEPROM of the robot/drone with the \"RC Control\" firmware through the settings>eeprom", rx - 2)
layout:setReturnLayout(infoLayout, uix.colors.green, " INFO ")
infoLayout:setReturnLayout(layout)

ui:loop()