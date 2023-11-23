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
local range = navigation.getRange()
if range > 512 then range = 512 end
local stubStr = string.rep(" ", 16)

----------------------------------

layout:createText(2, ry - 3, nil, "fixed map: ")
layout:createText(2, ry - 1, nil, "scale map: ")
local scaleText = layout:createText(2, 4)
local fixedMap = layout:createSwitch(13, ry - 3, false)
local positionLabel = layout:createText(2, 2)
local facingLabel = layout:createText(2, 3)
local scaleSeek = layout:createSeek(13, ry - 1, rx - (canvasSize * 2) - 13, nil, nil, nil, 1)
local updateWaypoints = layout:createButton(2, ry - 5, 19, 1, nil, nil, "refresh waypoints")
local canvas = layout:createCanvas(rx - ((canvasSize * 2) - 1), 1, canvasSize * 2, canvasSize, uix.colors.white, uix.colors.black)

----------------------------------

local waypoints = navigation.findWaypoints(math.huge)

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

local function getMapScale()
    return math.map(scaleSeek.value, 0, 1, 4, range)
end

local function update()
    local px, py, pz = navigation.getPosition()
    local facing = navigation.getFacing()

    if px then
        positionLabel.text = "local pos: " .. math.round(px) .. "x " .. math.round(py) .. "y " .. math.round(pz) .. "z" .. stubStr
    else
        positionLabel.text = "local pos: unknown" .. stubStr
    end
    facingLabel.text   = "facing   : " .. getFacingStr(facing) .. stubStr
    scaleText.text     = "map scale: " .. math.round(getMapScale()) .. stubStr
    positionLabel:draw()
    facingLabel:draw()
    scaleText:draw()

    canvas:clear()
    canvas:centerText(canvas.sx / 2, 1, nil, nil, "NORTH")
    canvas:centerText(canvas.sx / 2, canvas.sy, nil, nil, "SOUTH")
    canvas:centerText(1, canvas.sy / 2, nil, nil, "WEST", true)
    canvas:centerText(canvas.sx, canvas.sy / 2, nil, nil, "EAST", true)
end

function updateWaypoints:onClick()
    waypoints = navigation.findWaypoints(math.huge)
    update()
end

function scaleSeek:onSeek(value)
    update()
end

thread.timer(0, update)
thread.timer(3, update, math.huge)
manager:loop()