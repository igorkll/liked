local graphic = require("graphic")
local gui_container = require("gui_container")
local computer = require("computer")
local fs = require("filesystem")
local system = require("system")
local paths = require("paths")
local serialization = require("serialization")
local registry = require("registry")
local liked = require("liked")
local gui = require("gui")
local component = require("component")
local event = require("event")

local colors = gui_container.colors

------------------------------------

local screen, posX, posY = ...
local rx, ry = graphic.getResolution(screen)
local window = graphic.createWindow(screen, posX, posY, rx - (posX - 1), ry - (posY - 1))

------------------------------------

local labelReader = window:read(2, 2, 24, colors.lightGray, colors.black, "label: ", false, component.eeprom.getLabel() or "eeprom", true)
labelReader.setMaxStringLen(24)

local function redraw()
    window:clear(colors.black)
    labelReader.redraw()
end
redraw()

local oldLabel = labelReader.getBuffer()
local timerID = event.timer(1, function ()
    local lbl = labelReader.getBuffer()
    if oldLabel ~= lbl then
        component.eeprom.setLabel(lbl)
        oldLabel = lbl
    end
end, math.huge)

return function(eventData)
    local windowEventData = window:uploadEvent(eventData)
    labelReader.uploadEvent(windowEventData)

    if windowEventData[1] == "touch" then
        if windowEventData[3] >= 2 and windowEventData[3] <= 19 then
            if windowEventData[4] == 2 then
                --wipeUserData()
            elseif windowEventData[4] == 4 then
                --updateSystem()
            end
        end
    end
end, function ()
    component.eeprom.setLabel(labelReader.getBuffer())
    event.cancel(timerID)
end