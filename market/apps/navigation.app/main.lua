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
local crange = range
local stubStr = string.rep(" ", 16)

----------------------------------

layout:createText(2, ry - 5, nil, "passive mode: ")
layout:createText(2, ry - 3, nil, "fixed map: ")
layout:createText(2, ry - 1, nil, "scale map: ")

local positionLabel = layout:createText(2, 2)
local facingLabel = layout:createText(2, 3)
local scaleText = layout:createText(2, 4)
local waypointsLabel = layout:createText(2, 5)

local scaleSeek = layout:createSeek(13, ry - 1, rx - (canvasSize * 2) - 13, nil, nil, nil, 1)
local fixedMap = layout:createSwitch(13, ry - 3, false)
local passiveMode = layout:createSwitch(16, ry - 5, false)
local updateWaypoints = layout:createButton(2, ry - 7, 19, 1, nil, nil, "refresh waypoints")
local hideWaypoints = layout:createButton(2, ry - 9, 19, 1, nil, nil, "hide waypoints")
local canvas = layout:createCanvas(rx - ((canvasSize * 2) - 1), 1, canvasSize * 2, canvasSize, uix.colors.white, uix.colors.black)

----------------------------------

local waypoints = navigation.findWaypoints(math.huge)
local wpx, wpy, wpz = navigation.getPosition()
local lpx, lpy, lpz

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
    return math.mapRound(scaleSeek.value, 0, 1, 4, range)
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

local function drawSelf(x, y, facing, color)
    canvas:set(x, y, color or uix.colors.red, uix.colors.white, getRotationChar(facing))
end

local function toPosInMap(x, z)
    local px, py, pz = navigation.getPosition()
    if px then
        local ox, oz = x - px, z - pz
        local cx, cz = canvas.sx / 2, canvas.sy / 2

        if fixedMap.state then
            return math.mapRound(x, -crange, crange, 1, canvas.sx), math.mapRound(z, -crange, crange, 1, canvas.sy)
        else
            return math.mapRound(ox, -crange, crange, 1, canvas.sx), math.mapRound(oz, -crange, crange, 1, canvas.sy)
        end
    end
end

local function drawWaypoint(dx, dy, waypoint)
    canvas:set(dx, dy, waypoint.redstone > 0 and uix.colors.lime or uix.colors.green, uix.colors.white, "#")
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
    scaleText.text      = "map scale: " .. crange .. stubStr
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

    if px and not passiveMode.state then
        local dx, dy = toPosInMap(px, pz)
        if dx then
            drawSelf(dx, dy, facing)
        end

        if waypoints and wpx then
            for _, waypoint in ipairs(waypoints) do
                local dx, dy = toPosInMap(wpx + waypoint.position[1], wpz + waypoint.position[3])
                if dx then
                    drawWaypoint(dx, dy, waypoint)
                end
            end
        end
    else
        drawSelf(canvas.sx / 2, canvas.sy / 2, facing, uix.colors.orange)

        if waypoints then
            for _, waypoint in ipairs(waypoints) do
                drawWaypoint((canvas.sx / 2) + waypoint.position[1], (canvas.sy / 2) + waypoint.position[3], waypoint)
            end
        end
    end
end

function updateWaypoints:onClick()
    waypoints = navigation.findWaypoints(math.huge)
    wpx, wpy, wpz = navigation.getPosition()
    update()
end

function hideWaypoints:onClick()
    waypoints = nil
    wpx, wpy, wpz = nil, nil, nil
    update()
end

function scaleSeek:onSeek(value)
    crange = getMapScale()
    update()
end

function fixedMap:onSwitch()
    update()
end

function passiveMode:onSwitch()
    update()
end

thread.timer(0, update)
thread.timer(1, update, math.huge)
manager:loop()