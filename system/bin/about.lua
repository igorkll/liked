local graphic = require("graphic")
local event = require("event")
local gui_container = require("gui_container")

local colors = gui_container.colors
local screen = gui_container.screen
local gpu = graphic.findGpu(screen)
local rx, ry = gpu.getResolution()

--------------------------------------------

local window = graphic.classWindow:new(screen, 1, 2, rx, ry - 1, true)
window:clear(colors.white)

local strs = {
    "OS INFO",
    "-----------------OS",
    "distributive: liked",
    "distributive version: v0.1",
    "-----------------CORE",
    "OS core: likeOS",
    "core verion: " .. _COREVERSION,
    "core version id: " .. tostring(_COREVERSIONID)
}

for i, v in ipairs(strs) do
    window:write(v .. "\n", colors.white, colors.black)
end

window:set(rx, 1, colors.red, colors.white, "X")

while true do
    local eventData = {event.pull()}
    local windowEventData = window:uploadEvent(eventData)
    if windowEventData[1] == "touch" and windowEventData[3] == rx and windowEventData[4] == 1 then
        break
    end
    if eventData[1] == "closePressed" then
        break
    end
end