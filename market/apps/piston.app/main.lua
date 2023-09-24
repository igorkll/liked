local graphic = require("graphic")
local component = require("component")
local event = require("event")
local gui_container = require("gui_container")
local gui = require("gui")
local unicode = require("unicode")
local liked = require("liked")
local colors = gui_container.colors

local screen = ...
local piston = gui.selectcomponent(screen, nil, nil, {"piston"}, true)
if not piston then
    return
end
piston = component.proxy(piston)
local rx, ry = graphic.getResolution(screen)
local window = graphic.createWindow(screen, 1, 1, rx, ry, true)
local title = "Piston"

local placeAt = (rx // 2) - 4

local function updateAll()
    window:clear(colors.black)
    window:fill(1, 1, rx, 1, colors.gray, 0, " ")
    window:set((window.sizeX / 2) - (unicode.len(title) / 2), 1, colors.gray, colors.white, title)
    window:set(rx, 1, colors.red, colors.white, "X")

    window:set(placeAt, 3, colors.lime, colors.white, "           ")
    window:set(placeAt, 4, colors.lime, colors.white, "   PUSH    ")
    window:set(placeAt, 5, colors.lime, colors.white, "           ")

    local col = piston.pull and colors.green or colors.gray
    window:set(placeAt, 7, col, colors.white, "           ")
    window:set(placeAt, 8, col, colors.white, "   PULL    ")
    window:set(placeAt, 9, col, colors.white, "           ")
end
updateAll()

local function updateButton()
    local stateCol = _G.pistonBg and colors.green or colors.lightGray
    window:set(placeAt, 11, stateCol, colors.white, "           ")
    window:set(placeAt, 12, stateCol, colors.white, " AUTO PUSH ")
    window:set(placeAt, 13, stateCol, colors.white, "           ")

    local stateCol = _G.pistonBg2 and colors.green or colors.lightGray
    if not piston.pull then
        stateCol = colors.gray
    end
    window:set(placeAt, 15, stateCol, colors.white, "           ")
    window:set(placeAt, 16, stateCol, colors.white, " AUTO PULL ")
    window:set(placeAt, 17, stateCol, colors.white, "           ")
end
updateButton()

local function checkButton(windowEventData, startY)
    return windowEventData[3] >= placeAt and windowEventData[3] <= (placeAt + 10) and windowEventData[4] >= startY and windowEventData[4] <= startY + 2
end

while true do
    local eventData = {event.pull()}
    local windowEventData = window:uploadEvent(eventData)

    if windowEventData[1] == "touch" then
        if windowEventData[3] == rx and windowEventData[4] == 1 then
            break
        elseif checkButton(windowEventData, 3) then
            liked.assert(screen, piston.push())
        elseif checkButton(windowEventData, 7) then
            if piston.pull then
                liked.assert(screen, piston.pull())
            else
                local clear = saveZone(screen)
                gui.warn(screen, nil, nil, "this piston does not support \"pull\"")
                clear()
            end
        elseif checkButton(windowEventData, 11) then
            if _G.pistonBg then
                event.cancel(_G.pistonBg)
                _G.pistonBg = nil
            else
                _G.pistonBg = event.timer(0.3, function ()
                    pcall(piston.push)
                end, math.huge)
            end
            updateButton()
        elseif checkButton(windowEventData, 15) then
            if piston.pull then
                if _G.pistonBg2 then
                    event.cancel(_G.pistonBg2)
                    _G.pistonBg2 = nil
                else
                    _G.pistonBg2 = event.timer(0.3, function ()
                        pcall(piston.pull)
                    end, math.huge)
                end
                updateButton()
            else
                local clear = saveZone(screen)
                gui.warn(screen, nil, nil, "this piston does not support \"pull\"")
                clear()
            end
        end
    end
end