local uix = require("uix")
local gui = require("gui")
local thread = require("thread")
local sides = require("sides")

local screen = ...
local navigation = gui.selectcomponentProxy(screen, nil, nil, "navigation", true)
if not navigation then return end
local manager = uix.manager(screen)
local layout = manager:create("Navigation")
local rx, ry = manager:zoneSize()

local canvasSize = ry

----------------------------------

layout:createText(2, ry - 3, nil, "fixed map: ")
local fixedMap = layout:createSwitch(13, ry - 3, false)
local positionLabel = layout:createText(2, 2)
local facingLabel = layout:createText(2, 3)
local canvas = layout:createCanvas(rx - ((canvasSize * 2) - 1), 1, canvasSize * 2, canvasSize, uix.colors.white, uix.colors.black)

----------------------------------

local function getFacingStr(facing)
    if facing == sides.north then
        return "north"
    elseif facing == sides.south then
        return "south"
    elseif facing == sides.west then
        return "west"
    elseif facing == sides.east then
        return "east"
    else
        return "unknown"
    end
end

local function update()
    local px, py, pz = navigation.getPosition()
    local waypoints = navigation.findWaypoints(math.huge)
    local facing = navigation.getFacing()

    positionLabel.text = "local pos: " .. math.roundTo(px, 1) .. " " .. math.roundTo(py, 1) .. " " .. math.roundTo(pz, 1)
    facingLabel.text   = "facing   : " .. getFacingStr(facing)
    positionLabel:draw()
    facingLabel:draw()

    canvas:clear()
    canvas:centerText(canvas.sx / 2, 1, nil, nil, "NORTH")
    canvas:centerText(canvas.sx / 2, canvas.sy, nil, nil, "SOUTH")
    canvas:centerText(1, canvas.sy / 2, nil, nil, "WEST", true)
    canvas:centerText(canvas.sx, canvas.sy / 2, nil, nil, "EAST", true)
end

thread.timer(0, update)
thread.timer(1, update, math.huge)
manager:loop()