local thread = require("thread")
local graphic = require("graphic")
local uix = require("uix")
local event = require("event")
local gui_container = require("gui_container")
local colorslib = require("colors")

local colors = gui_container.colors

local screen = ...
local rx, ry = graphic.getResolution(screen)
local window = graphic.createWindow(screen, 1, 1, rx, ry)
local layout = uix.create(window, colors.black)
layout:createAutoUpBar("Switchs Demo")

local switchs = 0
for x = 2, rx - 5, 8 do
    for y = 3, ry - 1, 2 do
        switchs = switchs + 1
    end
end

local index = 0
for x = 2, rx - 5, 8 do
    for y = 3, ry - 1, 2 do
        index = index + 1
        local r, g, b = colorslib.hsvToRgb(math.round(math.map(index, 0, switchs, 0, 255)), 255, 255)
        local color = colorslib.blend(r, g, b)
        local color2 = colorslib.blend(r * 0.3, g * 0.3, b * 0.3)
        layout:createSwitch(x, y, math.random() > 0.5, color, color2)
    end
end

layout:draw()

while true do
    local eventData = {event.pull()}
    layout:uploadEvent(eventData)
end