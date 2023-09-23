local event = require("event")
local graphic = require("graphic")
local component = require("component")
local gui = require("gui")
local gui_container = require("gui_container")
local colors = gui_container.colors

local screen = ...
local piston = gui.selectcomponent(screen, nil, nil, {"piston"}, true)
if not piston then
    return
end

local rx, ry = graphic.getResolution()
local window = graphic.createWindow(screen, 1, 1, rx, ry, true)

window:clear(colors.black)
window:fill(1, 1, rx, 1, colors.gray, 0, " ")
window:set(rx, 1, colors.red, colors.white, "X")

while true do
    local eventData = {event.pull()}
    local windowEventData = window:uploadEvent(eventData)

    if windowEventData[1] == "touch" then
        if windowEventData[3] == rx and windowEventData[4] == 1 then
            break
        end
    end
end