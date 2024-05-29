local thread = require("thread")
local graphic = require("graphic")
local uix = require("uix")
local event = require("event")
local gui_container = require("gui_container")
local colorslib = require("colors")

local screen, layout, colors, rx, ry = ...
local fullDepth = graphic.getDepth(screen) == 8

local switchsCount = 0
for x = 2, rx - 5, 8 do
    for y = 3, ry - 1, 2 do
        switchsCount = switchsCount + 1
    end
end

local switchs = {}
local index = 0
for x = 2, rx - 5, 8 do
    for y = 2, ry - 4, 2 do
        index = index + 1
        local r, g, b = colorslib.hsvToRgb(math.round(math.map(index, 0, switchsCount, 0, 255)), 255, 255)
        local color = colorslib.blend(r, g, b)
        local color2 = fullDepth and colorslib.blend(r * 0.3, g * 0.3, b * 0.3) or colors.gray
        table.insert(switchs, layout:createSwitch(x, y, math.random() > 0.5, color, color2))
    end
end

local enableAll = layout:createButton(2, ry - 1, 16, 1, nil, nil, "Enable ALL")
function enableAll:onClick()
    for _, switch in ipairs(switchs) do
        switch.state = true
    end
    layout:draw()
end

local disableAll = layout:createButton(rx - 16, ry - 1, 16, 1, nil, nil, "Disable ALL")
function disableAll:onClick()
    for _, switch in ipairs(switchs) do
        switch.state = false
    end
    layout:draw()
end

local randomizeAll = layout:createButton(2 + 20, ry - 1, 16, 1, nil, nil, "Randomize ALL")
function randomizeAll:onClick()
    for _, switch in ipairs(switchs) do
        switch.state = math.random() > 0.5
    end
    layout:draw()
end

local invertAll = layout:createButton((rx - 16) - 20, ry - 1, 16, 1, nil, nil, "invert ALL")
function invertAll:onClick()
    for _, switch in ipairs(switchs) do
        switch.state = not switch.state
    end
    layout:draw()
end