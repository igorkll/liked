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

local positionLabel = layout:createText(2, 2)
local facingLabel = layout:createText(2, 3)
local scaleText = layout:createText(2, 4)
local waypointsLabel = layout:createText(2, 5)

local scaleSeek = layout:createSeek(13, ry - 1, rx - (canvasSize * 2) - 13, nil, nil, nil, 1)
local fixedMap = layout:createSwitch(13, ry - 3, false)
local updateWaypoints = layout:createButton(2, ry - 5, 19, 1, nil, nil, "refresh waypoints")
local hideWaypoints = layout:createButton(2, ry - 7, 19, 1, nil, nil, "hide waypoints")
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

local function getRotationChar(facing)
    if facing == sides.north then
        return "^"
    elseif facing == sides.south then
        return "V"
    elseif facing == sides.west then
        return "<"
    elseif facing == sides.east then
        return ">"
    else
        return "#"
    end
end

local function drawSelf(x, y, facing)
    canvas:set(x, y, uix.colors.red, uix.colors.white, getRotationChar(facing))
end

local function toPosInMap(x, z)
    local px, py, pz = navigation.getPosition()
    if px then
        local ox, oz = x - px, z - pz
        local cx, cz = canvas.sx / 2, canvas.sy / 2

        if fixedMap.state then
            return math.mapRound(px, -range, range, 1, canvas.sx), math.mapRound(pz, -range, range, 1, canvas.sy)
        else
            return math.mapRound(ox, -range, range, 1, canvas.sx), math.mapRound(oz, -range, range, 1, canvas.sy)
        end
    end
end

local function update()
    local px, py, pz = navigation.getPosition()
    local facing = navigation.getFacing()

    if px then
        positionLabel.text = "local pos: " .. math.round(px) .. "x " .. math.round(py) .. "y " .. math.round(pz) .. "z" .. stubStr
    else
        positionLabel.text = "local pos: unknown" .. stubStr
    end

    facingLabel.text    = "facing   : " .. getFacingStr(facing) .. stubStr
    scaleText.text      = "map scale: " .. math.round(getMapScale()) .. stubStr
    waypointsLabel.text = "waypoints: " .. (waypoints and #waypoints or "unknown") .. stubStr
    positionLabel:draw()
    facingLabel:draw()
    scaleText:draw()
    waypointsLabel:draw()

    canvas:clear()
    canvas:centerText(canvas.sx / 2, 1, nil, nil, "NORTH")
    canvas:centerText(canvas.sx / 2, canvas.sy, nil, nil, "SOUTH")
    canvas:centerText(1, canvas.sy / 2, nil, nil, "WEST", true)
    canvas:centerText(canvas.sx, canvas.sy / 2, nil, nil, "EAST", true)

    local dx, dy = toPosInMap(px, pz)
    if dx then
        drawSelf(dx, dy, facing)
    end
end

function updateWaypoints:onClick()
    waypoints = navigation.findWaypoints(math.huge)
    update()
end

function hideWaypoints:onClick()
    waypoints = nil
    update()
end

function scaleSeek:onSeek(value)
    update()
end

function fixedMap:onSwitch()
    update()
end

thread.timer(0, update)
thread.timer(1, update, math.huge)
manager:loop()