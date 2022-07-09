local graphic = require("graphic") --только при отрисовке в оперу лезет
local gui_container = require("gui_container")
local event = require("event")
local unicode = require("unicode")

local colors = gui_container.colors

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

local function redrawStrs(selected)
    for i, v in ipairs(strs) do
        local color = colors.white
        local color2 = colors.black
        if not active or active[i] then
            if selected == i then
                color = colors.blue
                color2 = colors.white
            end
            window:set(1, i, color, color2, strs[i] .. (string.rep(" ", sizeX - unicode.len(strs[i]))))
        else
            window:set(1, i, color, colors.lightGray, strs[i] .. (string.rep(" ", sizeX - unicode.len(strs[i]))))
        end
    end
end
redrawStrs()

local selectedNum
while true do
    local eventData = {event.pull()}
    if eventData[2] == screen then
        local windowEventData = window:uploadEvent(eventData)
        if windowEventData[1] == "drop" and windowEventData[5] == 0 then
            local num = windowEventData[4]
            if not active or active[num] then
                return strs[num], num
            end
        elseif (windowEventData[1] == "touch" or windowEventData[1] == "drag") and windowEventData[5] == 0 then
            if windowEventData[1] == "touch" and selectedNum and selectedNum == windowEventData[4] then
                if not active or active[selectedNum] then
                    return strs[selectedNum], selectedNum
                end
            end
            redrawStrs(windowEventData[4])
            selectedNum = windowEventData[4]
        elseif eventData[1] == "drag" then
            selectedNum = nil
            redrawStrs()
        elseif eventData[1] == "touch" or eventData[1] == "scroll" then
            event.push(table.unpack(eventData))
            return nil, nil
        end
    end
end