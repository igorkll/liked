local uix = require("uix")
local gobjs = require("gobjs")
local gui_container = require("gui_container")
local utils = require("utils")
local system = require("system")
local component = require("component")

local screen = ...
local port = 38710
local ui = uix.manager(screen)
local rx, ry = ui:zoneSize()
local modem = component.proxy(utils.findModem(true))

utils.openPort(modem, port)

-----------------------------

local layout = ui:create("controller", uix.colors.black)

local connectList = layout:createCustom(layout:customCenter(0, -4, gobjs.checkboxgroup, 32, 10))
layout:createVText(layout.sizeX / 2, connectList.y - 1, uix.colors.white, "list of devices")
connectList.oneSelect = true

connectList.list = {}
for i = 1, 32 do
    table.insert(connectList.list, {"TEST " .. i, false})
end

local passwordInput = layout:createInput(layout:centerOneSize(0, 2, 32, nil, nil, "*", nil, nil, nil, "password: "))
local connectButton = layout:createButton(layout:center(-6, 5, 16, 3, uix.colors.white, uix.colors.gray, "connect"))
local refreshButton = layout:createButton(layout:center(8, 5, 9, 3, uix.colors.orange, uix.colors.white, "refresh"))

function connectButton:onClick()
    rcLayout:select()
end

function refreshButton:onClick()
    connectList.list = {}
    connectList:draw()
end

-----------------------------

local infoLayout = ui:create("controller [INFO]", uix.colors.black)
infoLayout:createText(2, 2, uix.colors.white, gui_container.chars.dot .. " to use, flash the EEPROM of the robot/drone with the \"RC Control\" firmware through the settings>eeprom", rx - 2)
infoLayout:createText(2, 4, uix.colors.white, gui_container.chars.dot .. " if the robot has a screen and a video card, a random 8-character password will be set on it and it will be displayed on the screen", rx - 2)
infoLayout:createText(2, 6, uix.colors.white, gui_container.chars.dot .. " if the robot does not have a screen and/or a video card, then by default it will not have a password", rx - 2)
infoLayout:createText(2, 8, uix.colors.white, gui_container.chars.dot .. " there is always a screen on the drone and therefore a password will be set for the drone in any case", rx - 2)
infoLayout:createText(2, 10, uix.colors.white, gui_container.chars.dot .. " after that, you can hide the password display", rx - 2)
layout:setReturnLayout(infoLayout, uix.colors.green, " INFO ")
infoLayout:setReturnLayout(layout)

-----------------------------

rcLayout = ui:create("controller [RC Control]", uix.colors.black)
rcLayout:setReturnLayout(layout)

ui:loop()