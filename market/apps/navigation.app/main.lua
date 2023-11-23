local uix = require("uix")
local gui = require("gui")
local thread = require("thread")

local screen = ...
local navigation = gui.selectcomponentProxy(screen, nil, nil, "navigation", true)
if not navigation then return end
local manager = uix.manager(screen)
local rx, ry = manager:size()
local layout = manager:create("Navigation")


local canvasSize = ry - 1

local positionLabel = layout:createText(2, 2)
local canvas = layout:createCanvas(rx - ((canvasSize * 2) - 1), 1, canvasSize * 2, canvasSize, uix.colors.white, uix.colors.black)


local function update()
    local px, py, pz = navigation.getPosition()
    local waypoints = navigation.findWaypoints(math.huge)

    positionLabel.text = "x: " .. math.roundTo(px, 1) .. " y: " .. math.roundTo(py, 1) .. " z: " .. math.roundTo(pz, 1)
    positionLabel:draw()

    canvas:clear()
    canvas:centerText(canvas.sx / 2, 1, nil, nil, "NORTH")
    canvas:centerText(canvas.sx / 2, canvas.sy, nil, nil, "SOUTH")
    canvas:centerText(1, canvas.sy / 2, nil, nil, "WEST", true)
    canvas:centerText(canvas.sx, canvas.sy / 2, nil, nil, "EAST", true)
end

thread.timer(0, update)
thread.timer(1, update, math.huge)
manager:loop()