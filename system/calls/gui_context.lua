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
window:fill(1, 1, window.sizeX, window.sizeY, colors.white, 0, " ")

for i, v in ipairs(strs) do
    if not active or active[i] then
        window:set(1, i, colors.white, colors.black, v)
    else
        window:set(1, i, colors.white, colors.lightGray, v)
    end
end

while true do
    local eventData = {event.pull()}
    local windowEventData = window:uploadEvent(eventData)
    if windowEventData[1] == "touch" and windowEventData[5] == 0 then
        local num = windowEventData[4]
        if not active or active[num] then
            window:set(1, num, colors.blue, colors.white, strs[num] .. (string.rep(" ", sizeX - unicode.len(strs[num]))))
            event.sleep(0.1)
            return strs[num], num
        end
    else
        if eventData[1] == "touch" or
        eventData[1] == "drag" or 
        eventData[1] == "scroll" then
            event.push(table.unpack(eventData))
            return nil, nil
        end
    end
end