local graphic = require("graphic")
local gui_container = require("gui_container")
local uix = require("uix")
local gui = require("gui")
local component = require("component")
local event = require("event")

local colors = gui_container.colors

------------------------------------

local screen, posX, posY = ...
local rx, ry = graphic.getResolution(screen)
local window = graphic.createWindow(screen, posX, posY, rx - (posX - 1), ry - (posY - 1))

local layout = uix.create(window)
local flashButton = layout:createButton(2, 4, 16, 1, colors.white, colors.gray, "flash")
layout:draw()

function flashButton:onClick()
    self.state = false
    self:draw()
    graphic.forceUpdate()
    os.sleep(0.1)

    
end

------------------------------------

local labelReader = window:read(8, 2, 32, colors.lightGray, colors.black, nil, false, component.eeprom.getLabel() or "EEPROM", true)
labelReader.setMaxStringLen(24)

local function redraw()
    window:clear(colors.black)
    window:set(2, 2, colors.lightGray, colors.black, "label")
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
    layout:uploadEvent(windowEventData)

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