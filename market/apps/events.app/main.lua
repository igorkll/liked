local graphic = require("graphic")
local event = require("event")
local gui_container = require("gui_container")
local liked = require("liked")
local thread = require("thread")

local colors = gui_container.colors

--------------------------------

local screen = ...

local sizeX, sizeY = graphic.getResolution(screen)
local window = graphic.createWindow(screen, 1, 1, sizeX, sizeY)

local upTh, upRedraw, upCallbacks = liked.drawFullUpBarTask(screen, "Events")
local baseTh = thread.current()
upCallbacks.exit = function ()
    baseTh:kill()
end

local function update()
    window:clear(colors.black)
    upRedraw()
end

update()

--------------------------------

while true do
    local eventData = {event.pull()}
    local windowEventData = window:uploadEvent(eventData)

    local output = {}
    for k, v in pairs(eventData) do
        eventData[k] = tostring(v)
    end

    window:copy(1, 3, sizeX, sizeY - 2, 0, -1)
    window:fill(1, sizeY, sizeX, 1, colors.black, colors.white, " ")
    window:set(1, sizeY, colors.black, colors.white, table.concat(eventData, "  "))
end