local graphic = require("graphic")
local fs = require("filesystem")
local event = require("event")
local gui_container = require("gui_container")

local colors = gui_container.colors

------------------------------------

local screen = ...
local gpu = graphic.findGpu(screen)
local rx, ry = gpu.getResolution()

local statusWindow = graphic.classWindow:new(screen, 1, 1, rx, 1)
local mainWindow = graphic.classWindow:new(screen, 1, 2, rx - 8, ry - 1)
local paletteWindow = graphic.classWindow:new(screen, rx - 7, 2, 8, 18)
local nullWindow2 = graphic.classWindow:new(screen, rx - 7, 2 + paletteWindow.sizeY, 8, ry - 19)

------------------------------------

local selectedColor = 1
local function draw()
    statusWindow:clear(colors.gray)
    mainWindow:clear(colors.lightGray)
    paletteWindow:fill(1, 1, paletteWindow.sizeX, paletteWindow.sizeY, colors.brown, colors.black, "▒")
    for i, v in ipairs(gui_container.indexsColors) do
        paletteWindow:set(2, i + 1, v, 0, "      ")
    end
    nullWindow2:fill(1, 1, nullWindow2.sizeX, nullWindow2.sizeY, colors.green, colors.black, "▒")
    nullWindow2:fill(2, 2, nullWindow2.sizeX - 2, nullWindow2.sizeY - 2, gui_container.indexsColors[selectedColor], 0, " ")

    statusWindow:set(1, 1, colors.red, colors.white, "X")
    statusWindow:set(rx - 5, 1, colors.gray, colors.white, "paint")

    statusWindow:set(3, 1, colors.white, colors.black, "file")
    statusWindow:set(8, 1, colors.white, colors.black, "settings")
end
draw()

while true do
    local eventData = {event.pull()}
    local statusWindowEventData = statusWindow:uploadEvent(eventData)

    if statusWindowEventData[1] == "touch" then
        if statusWindowEventData[3] == 1 and statusWindowEventData[4] == 1 then
            break
        end
    end
end