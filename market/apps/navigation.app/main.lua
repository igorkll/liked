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
local canvas = layout:createCanvas(rx - ((canvasSize * 2) - 1), 1, canvasSize * 2, canvasSize, uix.colors.white)



local function update()
    local px, py, pz = navigation.getPosition()

    positionLabel.text = "x: " .. math.roundTo(px, 1) .. " y: " .. math.roundTo(py, 1) .. " z: " .. math.roundTo(pz, 1)
    positionLabel:draw()

    canvas:set(2, 2, uix.colors.white, uix.colors.black, "ASDASD")
end

thread.timer(0, update)
thread.timer(1, update, math.huge)

manager:loop()