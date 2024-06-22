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
local modem = component.proxy(utils.findModem(true) or "")

if modem then
    utils.openPort(modem, port)
end

-----------------------------

local layout = ui:create("controller", uix.colors.black)
local warnMsg

if not modem then
    warnMsg = layout:createText(2, layout.sizeY - 1, uix.colors.red, "the modem was not found! install a modem to use the app")
elseif not modem.isWireless() then
    warnMsg = layout:createText(2, layout.sizeY - 1, uix.colors.orange, "only a wired modem was found")
end

local connectList = layout:createCustom(layout:customCenter(0, -4, gobjs.checkboxgroup, 32, 10))
layout:createVText(layout.sizeX / 2, connectList.y - 1, uix.colors.white, "list of devices")
connectList.oneSelect = true

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

layout:listen("modem_message", function (eventData)
    if eventData[2] == modem.address and eventData[4] == port and eventData[6] == "rc_adv" then
        local tbl = {eventData[7] .. " " .. eventData[3]:sub(1, 6) .. math.roundTo(eventData[5]), false, eventData[3]}
        for i = 1, #connectList.list do
            if tbl[i][3] == eventData[3] then
                connectList.list[i] = tbl
                tbl = nil
                break
            end
        end
        if tbl then
            table.insert(connectList.list, tbl)
        end
        connectList:draw()
    end
end)

-----------------------------

local infoLayout = ui:create("controller [INFO]", uix.colors.black)
infoLayout:createText(2, 2, uix.colors.white, gui_container.chars.dot .. " to use, flash the EEPROM of the robot/drone with the \"RC Bios\" firmware through the settings>eeprom", rx - 2)
infoLayout:createText(2, 4, uix.colors.white, gui_container.chars.dot .. " if the robot has a screen and a video card, a random 8-character password will be set on it and it will be displayed on the screen", rx - 2)
infoLayout:createText(2, 6, uix.colors.white, gui_container.chars.dot .. " if the robot does not have a screen and/or a video card, then by default it will not have a password", rx - 2)
infoLayout:createText(2, 8, uix.colors.white, gui_container.chars.dot .. " there is always a screen on the drone and therefore a password will be set for the drone in any case", rx - 2)
infoLayout:createText(2, 10, uix.colors.white, gui_container.chars.dot .. " the password will be generated randomly every time you start unless you set your password", rx - 2)
infoLayout:createText(2, 12, uix.colors.white, gui_container.chars.dot .. " in fact, the \"RC Bios\" can be installed on any device, be it a computer or a microcontroller", rx - 2)
infoLayout:createText(2, 14, uix.colors.white, gui_container.chars.dot .. " if a password is not set on the device and a random temporary one cannot be generated (due to the lack of a screen or GPU), then you cannot connect to the device from a distance of more than 8 blocks", rx - 2)
layout:setReturnLayout(infoLayout, uix.colors.green, " INFO ")
infoLayout:setReturnLayout(layout)

-----------------------------

rcLayout = ui:create("controller [Remote Control]", uix.colors.black)
rcLayout:setReturnLayout(layout)

ui:loop()