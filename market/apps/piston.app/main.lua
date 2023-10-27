local graphic = require("graphic")
local component = require("component")
local event = require("event")
local gui_container = require("gui_container")
local gui = require("gui")
local sides = require("sides")
local liked = require("liked")
local thread = require("thread")
local colors = gui_container.colors

local screen = ...
local piston = gui.selectcomponent(screen, nil, nil, {"piston"}, true)
if not piston then
    return
end
piston = component.proxy(piston)
local rx, ry = graphic.getResolution(screen)
local window = graphic.createWindow(screen, 1, 1, rx, ry, true)

local upTh, upRedraw, upCallbacks = liked.drawFullUpBarTask(screen, "Piston")
local baseTh = thread.current()
upCallbacks.exit = function ()
    baseTh:kill()
end

local placeAt = (rx // 2) - 4
local placeAt2 = (rx // 2) + 10

_G.pistonCurrentSide = _G.pistonCurrentSide or {}
_G.pistonBg = _G.pistonBg or {}
_G.pistonBg2 = _G.pistonBg2 or {}

_G.pistonCurrentSide[piston] = _G.pistonCurrentSide[piston] or sides.front

local function updateAll()
    window:clear(colors.black)
    window:fill(1, 1, rx, 1, colors.gray, 0, " ")
    upRedraw()

    window:set(placeAt, 3, colors.lime, colors.white, "           ")
    window:set(placeAt, 4, colors.lime, colors.white, "   PUSH    ")
    window:set(placeAt, 5, colors.lime, colors.white, "           ")

    local col = piston.pull and colors.green or colors.gray
    window:set(placeAt, 7, col, colors.white, "           ")
    window:set(placeAt, 8, col, colors.white, "   PULL    ")
    window:set(placeAt, 9, col, colors.white, "           ")
end
updateAll()

local function updateButtons()
    local stateCol = _G.pistonBg[piston] and colors.green or colors.lightGray
    window:set(placeAt, 11, stateCol, colors.white, "           ")
    window:set(placeAt, 12, stateCol, colors.white, " AUTO PUSH ")
    window:set(placeAt, 13, stateCol, colors.white, "           ")

    local stateCol = _G.pistonBg2[piston] and colors.green or colors.lightGray
    if not piston.pull then
        stateCol = colors.gray
    end
    window:set(placeAt, 15, stateCol, colors.white, "           ")
    window:set(placeAt, 16, stateCol, colors.white, " AUTO PULL ")
    window:set(placeAt, 17, stateCol, colors.white, "           ")


    local stateCol = _G.pistonCurrentSide[piston] == sides.front and colors.red or colors.lightGray
    window:set(placeAt2, 3, stateCol, colors.white, "           ")
    window:set(placeAt2, 4, stateCol, colors.white, "   FRONT   ")
    window:set(placeAt2, 5, stateCol, colors.white, "           ")

    local stateCol = _G.pistonCurrentSide[piston] == sides.up and colors.red or colors.lightGray
    window:set(placeAt2, 7, stateCol, colors.white, "           ")
    window:set(placeAt2, 8, stateCol, colors.white, "     UP    ")
    window:set(placeAt2, 9, stateCol, colors.white, "           ")

    local stateCol = _G.pistonCurrentSide[piston] == sides.bottom and colors.red or colors.lightGray
    window:set(placeAt2, 11, stateCol, colors.white, "           ")
    window:set(placeAt2, 12, stateCol, colors.white, "  BOTTOM   ")
    window:set(placeAt2, 13, stateCol, colors.white, "           ")
end
updateButtons()

local function checkButton(windowEventData, startY)
    return windowEventData[3] >= placeAt and windowEventData[3] <= (placeAt + 10) and windowEventData[4] >= startY and windowEventData[4] <= startY + 2
end

local function checkButton2(windowEventData, startY)
    return windowEventData[3] >= placeAt2 and windowEventData[3] <= (placeAt2 + 10) and windowEventData[4] >= startY and windowEventData[4] <= startY + 2
end

while true do
    local eventData = {event.pull()}
    local windowEventData = window:uploadEvent(eventData)

    if windowEventData[1] == "touch" then
        if checkButton(windowEventData, 3) then
            liked.assert(screen, piston.push(_G.pistonCurrentSide[piston]))
        elseif checkButton(windowEventData, 7) then
            if piston.pull then
                liked.assert(screen, piston.pull(_G.pistonCurrentSide[piston]))
            else
                local clear = saveZone(screen)
                gui.warn(screen, nil, nil, "this piston does not support \"pull\"")
                clear()
            end
        elseif checkButton(windowEventData, 11) then
            if _G.pistonBg[piston] then
                event.cancel(_G.pistonBg[piston])
                _G.pistonBg[piston] = nil
            else
                _G.pistonBg[piston] = event.timer(0.3, function ()
                    pcall(piston.push, _G.pistonCurrentSide[piston])
                end, math.huge)
            end
            updateButtons()
        elseif checkButton(windowEventData, 15) then
            if piston.pull then
                if _G.pistonBg2[piston] then
                    event.cancel(_G.pistonBg2[piston])
                    _G.pistonBg2[piston] = nil
                else
                    _G.pistonBg2[piston] = event.timer(0.3, function ()
                        pcall(piston.pull, _G.pistonCurrentSide[piston])
                    end, math.huge)
                end
                updateButtons()
            else
                local clear = saveZone(screen)
                gui.warn(screen, nil, nil, "this piston does not support \"pull\"")
                clear()
            end
        elseif checkButton2(windowEventData, 3) then
            _G.pistonCurrentSide[piston] = sides.front
            updateButtons()
        elseif checkButton2(windowEventData, 7) then
            _G.pistonCurrentSide[piston] = sides.up
            updateButtons()
        elseif checkButton2(windowEventData, 11) then
            _G.pistonCurrentSide[piston] = sides.bottom
            updateButtons()
        end
    end
end