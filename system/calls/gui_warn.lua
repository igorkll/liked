local graphic = require("graphic")
local explorer = require("explorer")

local colors = explorer.colors

------------------------------------

local screen, str = ...
local gpu = graphic.findGpu(screen)

local cx, cy = gpu.getResolution()
cx = cx / 2
cy = cy / 2
cx = cx - 16
cy = cy - 4
cx = math.floor(cx)
cy = math.floor(cy)

local window = graphic.classWindow:new(screen, cx, cy, 32, 8)

window:fill(2, 2, window.sizeX, window.sizeY, colors.gray, 0, " ")
window:clear(colors.lightGray)
window:set(10, 2, colors.lightGray, colors.white, str)

window:set(2, 2, colors.lightGray, colors.yellow, "  █")
window:set(2, 3, colors.lightGray, colors.yellow, " ███ ")
window:set(2, 4, colors.lightGray, colors.yellow, "█████")
window:set(4, 3, colors.yellow, colors.white, "!")

window:set(32 - 4, 7, colors.blue, colors.white, " ok ")

while true do
    local eventData = {event.pull()}
    local windowEventData = window:uploadEvent(eventData)
    if windowEventData[4] == 7 and windowEventData[3] > (32 - 5) and windowEventData[3] <= ((32 - 5) + 4) then
        break
    end
end