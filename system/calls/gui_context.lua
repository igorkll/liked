local graphic = require("graphic") --только при отрисовке в оперу лезет
local explorer = require("explorer")
local event = require("event")
local unicode = require("unicode")

local colors = explorer.colors

------------------------------------

local screen, posX, posY, strs, active = ...
local gpu = graphic.findGpu(screen)
local cx, cy = gpu.getResolution()

local sizeX, sizeY = 0, #strs
for i, v in ipairs(strs) do
    if unicode.len(v) > sizeX then
        sizeX = unicode.len(v)
    end
end

local window = graphic.classWindow:new(screen, posX, posY, sizeX, sizeY)
window:fill(2, 2, window.sizeX, window.sizeY, colors.gray, 0, " ")
window:fill(1, 1, window.sizeX, window.sizeY, colors.lightGray, 0, " ")

for i, v in ipairs(strs) do
    if not active or active[i] then
        window:set(1, i, colors.lightGray, colors.black, v)
    else
        window:set(1, i, colors.lightGray, colors.gray, v)
    end
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