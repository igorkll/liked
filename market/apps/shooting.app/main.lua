local draw = require("draw")
local colors = require("colors")
local liked = require("liked")
local thread = require("thread")
local event = require("event")
local graphic = require("graphic")

local screen = ...
local rx, ry = graphic.getResolution(screen)
liked.drawFullUpBarTask(screen, "Shooting")
liked.regExit(screen, nil, true)

local showWindowSizeX = ry * 2

local shotWindow = graphic.createWindow(screen, 1, 2, showWindowSizeX, ry - 1)
local appWindow = graphic.createWindow(screen, showWindowSizeX + 1, 2, rx - showWindowSizeX, ry - 1)
local render = draw.create(shotWindow, draw.modes.semi)
local sx, sy = render:size()

local cr = (sx / 2) - 2
local cx, cy = (sx / 2) - 1, sy / 2

local function redraw()
    appWindow:clear(draw.colors.black)

    render:clear(draw.colors.lightGray)
    local state = false
    for r = cr, 2, -3 do
        local color = state and draw.colors.gray or draw.colors.white
        if r == 2 then
            color = draw.colors.red
        end
        render:circle(cx, cy, r, color)
        state = not state
    end
end
redraw()

while true do
    local eventData = {event.pull()}
    local shotEventData = render:touchscreen(eventData)
    if shotEventData and shotEventData[1] == "touch" then
        render:dot(shotEventData[3], shotEventData[4], draw.colors.yellow)
    end
end