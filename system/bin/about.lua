local graphic = require("graphic")
local event = require("event")
local gui_container = require("gui_container")

local colors = gui_container.colors
local screen = gui_container.screen
local gpu = graphic.findGpu(screen)
local rx, ry = gpu.getResolution()

--------------------------------------------

local window = graphic.classWindow:new(screen, 1, 2, rx, ry - 1, true)
window:clear(colors.lightGray)

local strs = {
    "OS INFO",
    "distributive: liked",
    "core verion: " .. _COREVERSION, "core version id:" .. tostring(_G._COREVERSIONID)
}

for i, v in ipairs(strs) do
    window:write(v, colors.lightGray, colors.gray)
end

window:set(rx, 1, colors.red, colors.white, "X")

while true do
    local eventData = {event.pull()}
    local windowEventData = window:uploadEvent(eventData)
    if windowEventData[1] == "touch" and windowEventData[3] == rx and windowEventData[4] == 1 then
        break
    end
end