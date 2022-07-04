local graphic = require("graphic") --только при отрисовке в оперу лезет
local explorer = require("explorer")
local event = require("event")

local colors = explorer.colors

------------------------------------

local screen, strs, posX, posY = ...
local gpu = graphic.findGpu(screen)

local cx, cy = gpu.getResolution()

local sizeX, sizeY = 0, 0
local window = graphic.classWindow:new(screen, posX, posY, sizeX, sizeY)
window:fill(2, 2, window.sizeX, window.sizeY, colors.gray, 0, " ")
window:fill(1, 1, window.sizeX, window.sizeY, colors.lightGray, 0, " ")

for i, v in ipairs(strs) do
    
end

while true do
    local eventData = {event.pull()}
    local windowEventData = window:uploadEvent(eventData)
    if windowEventData[1] == "touch" and windowEventData[5] == 0 then
        if windowEventData[4] == 7 and windowEventData[3] > (32 - 5) and windowEventData[3] <= ((32 - 5) + 4) then
            window:set(32 - 4, 7, colors.lightBlue, colors.white, " ok ")
            event.sleep(0.1)
            break
        end
    end
end