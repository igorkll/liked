local graphic = require("graphic") --только при отрисовке в оперу лезет
local gui_container = require("gui_container")
local event = require("event")
local calls = require("calls")

local colors = gui_container.colors

------------------------------------

local screen, cx, cy, str, backgroundColor = ...
local gpu = graphic.findGpu(screen)

if not cx or not cy then
    cx, cy = gpu.getResolution()
    cx = cx / 2
    cy = cy / 2
    cx = cx - 16
    cy = cy - 4
    cx = math.floor(cx)
    cy = math.floor(cy)
end

local window = graphic.classWindow:new(screen, cx, cy, 32, 8)

window:fill(2, 2, window.sizeX, window.sizeY, colors.gray, 0, " ")
window:clear(backgroundColor or colors.lightGray)

local strs = calls.call("split", str, "\n")
local newstrs = {}
for i, v in ipairs(strs) do
    local lnewstrs = calls.call("toParts", v, 22)
    for i, v in ipairs(lnewstrs) do
        table.insert(newstrs, v)
    end
end

for i, v in ipairs(newstrs) do
    window:set(10, i + 1, colors.lightGray, colors.white, v)
end

window:set(2, 2, colors.lightGray, colors.yellow, "  █  ")
window:set(2, 3, colors.lightGray, colors.yellow, " ███ ")
window:set(2, 4, colors.lightGray, colors.yellow, "█████")
window:set(4, 3, colors.yellow, colors.white, "!")

window:set(32 - 4, 7, colors.lightBlue, colors.white, " ok ")

while true do
    local eventData = {event.pull()}
    local windowEventData = window:uploadEvent(eventData)
    if windowEventData[1] == "touch" and windowEventData[5] == 0 then
        if windowEventData[4] == 7 and windowEventData[3] > (32 - 5) and windowEventData[3] <= ((32 - 5) + 4) then
            window:set(32 - 4, 7, colors.blue, colors.white, " ok ")
            event.sleep(0.1)
            break
        end
    end
end