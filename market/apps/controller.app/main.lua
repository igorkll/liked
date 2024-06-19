local uix = require("uix")
local gui_container = require("gui_container")

local screen = ...
local ui = uix.manager(screen)
local rx, ry = ui:zoneSize()

----------------------------- ui

layout = ui:create("controller", uix.colors.black)
layout:createButton(uix:center(0, 0, 16, 3, uix.colors.white, uix.colors.black, "connect"))

infoLayout = ui:create("controller [INFO]", uix.colors.black)
infoLayout:createText(2, 2, uix.colors.white, gui_container.chars.dot .. " to use, flash the EEPROM of the robot/drone with the \"RC Control\" firmware through the settings>eeprom", rx - 2)
infoLayout:createText(2, 4, uix.colors.white, gui_container.chars.dot .. " if the robot has a screen and a video card, a random 8-character password will be set on it and it will be displayed on the screen", rx - 2)
infoLayout:createText(2, 6, uix.colors.white, gui_container.chars.dot .. " if the robot does not have a screen and/or a video card, then by default it will not have a password", rx - 2)
infoLayout:createText(2, 8, uix.colors.white, gui_container.chars.dot .. " there is always a screen on the drone and therefore a password will be set for the drone in any case", rx - 2)
infoLayout:createText(2, 10, uix.colors.white, gui_container.chars.dot .. " after that, you can hide the password display", rx - 2)
layout:setReturnLayout(infoLayout, uix.colors.green, " INFO ")
infoLayout:setReturnLayout(layout)

rcLayout = ui:create("controller [RC Control]", uix.colors.black)
rcLayout:setReturnLayout(layout)

ui:loop()