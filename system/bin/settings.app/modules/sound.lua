local graphic = require("graphic")
local fs = require("filesystem")
local gui_container = require("gui_container")
local paths = require("paths")
local unicode = require("unicode")
local event = require("event")
local calls = require("calls")
local computer = require("computer")
local registry = require("registry")

local colors = gui_container.colors

------------------------------------

local screen, posX, posY = ...
local gpu = graphic.findGpu(screen)
local rx, ry = gpu.getResolution()

------------------------------------

local selectWindow = graphic.createWindow(screen, posX, posY, rx - (posX - 1), ry - (posY - 1))

------------------------------------

local users = {}

local function draw()
    users = {}

    selectWindow:clear(colors.black)
    selectWindow:set(3, 1, colors.green, colors.white, "ENABLE")
    selectWindow:set(3, 2, colors.red, colors.white, "DISABLE")

    selectWindow:set(1, registry.soundEnable and 1 or 2, colors.black, colors.white, "> ")
end

draw()

------------------------------------

return function(eventData)
    local selectWindowEventData = selectWindow:uploadEvent(eventData)

    if selectWindowEventData[1] == "touch" then
        if selectWindowEventData[4] == 1 then
            registry.soundEnable = true
        elseif selectWindowEventData[4] == 2 then
            registry.soundEnable = false
        end
        draw()
    end
end