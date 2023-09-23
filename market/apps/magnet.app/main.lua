local graphic = require("graphic")
local component = require("component")
local event = require("event")
local gui_container = require("gui_container")
local gui = require("gui")
local unicode = require("unicode")
local colors = gui_container.colors

local screen = ...
local magnet = gui.selectcomponent(screen, nil, nil, {"tractor_beam"}, true)
if not magnet then
    return
end
magnet = component.proxy(magnet)
local rx, ry = graphic.getResolution(screen)
local window = graphic.createWindow(screen, 1, 1, rx, ry, true)
local title = "Magnet"

local function updateAll()
    window:clear(colors.black)
    window:fill(1, 1, rx, 1, colors.gray, 0, " ")
    window:set((window.sizeX / 2) - (unicode.len(title) / 2), 1, colors.gray, colors.white, title)
    window:set(rx, 1, colors.red, colors.white, "X")

    window:set(2, 3, colors.red, colors.white, "           ")
    window:set(2, 4, colors.red, colors.white, "   SUCK    ")
    window:set(2, 5, colors.red, colors.white, "           ")

    window:set(2, 7, colors.orange, colors.white, "           ")
    window:set(2, 8, colors.orange, colors.white, " SUCK ALL  ")
    window:set(2, 9, colors.orange, colors.white, "           ")
end
updateAll()

local function updateButton()
    local stateCol = _G.magnetBg and colors.green or colors.red
    window:set(2, 11, stateCol, colors.white, "           ")
    window:set(2, 12, stateCol, colors.white, " AUTO SUCK ")
    window:set(2, 13, stateCol, colors.white, "           ")
end
updateButton()

local function checkButton(windowEventData, startY)
    return windowEventData[3] >= 2 and windowEventData[3] <= 12 and windowEventData[4] >= startY and windowEventData[4] <= startY + 2
end

while true do
    local eventData = {event.pull()}
    local windowEventData = window:uploadEvent(eventData)

    if windowEventData[1] == "touch" then
        if windowEventData[3] == rx and windowEventData[4] == 1 then
            break
        elseif checkButton(windowEventData, 3) then
            magnet.suck()
        elseif checkButton(windowEventData, 7) then
            gui_status(screen, nil, nil, "sucking...")
            while magnet.suck() do
                os.sleep(0.1)
            end
            updateAll()
            updateButton()
        elseif checkButton(windowEventData, 11) then
            if _G.magnetBg then
                event.cancel(_G.magnetBg)
                _G.magnetBg = nil
            else
                _G.magnetBg = event.timer(0.1, function ()
                    pcall(magnet.suck)
                end, math.huge)
            end
            updateButton()
        end
    end
end