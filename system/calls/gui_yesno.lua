local graphic = require("graphic")
local gui_container = require("gui_container")
local event = require("event")
local calls = require("calls")
local computer = require("computer")
local unicode = require("unicode")

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
    cx = math.floor(cx) + 1
    cy = math.floor(cy) + 1
end

local window = graphic.createWindow(screen, cx, cy, 32, 8, true)
local color = backgroundColor or colors.lightGray

--window:fill(2, 2, window.sizeX, window.sizeY, colors.gray, 0, " ")
require("gui").shadow(gpu, window.x, window.y, window.sizeX, window.sizeY)
window:clear(color)

for i, v in ipairs(calls.call("restrs", str, 22)) do
    local textColor = colors.white
    if color == textColor then
        textColor = colors.black
    end
    window:set(10, i + 1, color, textColor, v)
end

--window:set(2, 2, color, colors.green, "  █")
--window:set(2, 3, color, colors.green, " ███ ")
--window:set(2, 4, color, colors.green, "█████")

window:set(2, 2, color, colors.green, "  " .. unicode.char(0x2800+192) ..  "  ")
window:set(2, 3, color, colors.green, " ◢█◣ ")
window:set(2, 4, color, colors.green, "◢███◣")
window:set(4, 3, colors.green, colors.white, "?")

window:set(32 - 5, 7, colors.lime, colors.white, " yes ")
window:set(2, 7, colors.red, colors.white, " no ")

graphic.forceUpdate()
if require("registry").soundEnable then
    computer.beep(2000)
end

local function drawYes()
    window:set(32 - 5, 7, colors.green, colors.white, " yes ")
    graphic.forceUpdate()
    event.sleep(0.1)
end

while true do
    local eventData = {computer.pullSignal()}
    local windowEventData = window:uploadEvent(eventData)
    if windowEventData[1] == "touch" and windowEventData[5] == 0 then
        if windowEventData[4] == 7 and windowEventData[3] > (32 - 6) and windowEventData[3] <= ((32 - 5) + 4) then
            drawYes()
            return true
        elseif windowEventData[4] == 7 and windowEventData[3] >= 2 and windowEventData[3] <= (2 + 3) then
            window:set(2, 7, colors.orange, colors.white, " no ")
            graphic.forceUpdate()
            event.sleep(0.1)
            return false
        end
    elseif windowEventData[1] == "key_down" and windowEventData[4] == 28 then
        drawYes()
        return true
    end
end