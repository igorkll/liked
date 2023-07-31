local graphic = require("graphic")
local gui_container = require("gui_container")
local computer = require("computer")
local unicode = require("unicode")
local event = require("event")

local colors = gui_container.colors

------------------------------------

local screen, cx, cy, str, crypto, backgroundColor = ...
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

local window = graphic.createWindow(screen, cx, cy, 32, 8, true)

window:fill(2, 2, window.sizeX, window.sizeY, colors.gray, 0, " ")
window:clear(backgroundColor or colors.lightGray)

local pos = math.floor(((window.sizeX / 2) - (unicode.len(str) / 2)) + 0.5)
window:fill(1, 1, window.sizeX, 1, colors.gray, 0, " ")
window:set(pos, 1, colors.gray, colors.white, str)

window:set(32 - 4, 7, colors.lightBlue, colors.white, " ok ")
window:set(2, 7, colors.red, colors.white, " cancel ")

local reader = window:read(2, 3, window.sizeX - 2, colors.gray, colors.white, nil, crypto)

event.sleep(0.05)
if require("registry").soundEnable then
    computer.beep(2000)
    computer.beep(1500)
end

while true do
    local eventData = {computer.pullSignal()}
    local out = reader.uploadEvent(eventData)
    if out then
        if out == true then
            return false
        end
        return out
    end
    local windowEventData = window:uploadEvent(eventData)
    if windowEventData[1] == "touch" and windowEventData[5] == 0 then
        if windowEventData[4] == 7 and windowEventData[3] > (32 - 5) and windowEventData[3] <= ((32 - 5) + 4) then
            window:set(32 - 4, 7, colors.blue, colors.white, " ok ")
            event.sleep(0.05)
            return reader.getBuffer()
        elseif windowEventData[4] == 7 and windowEventData[3] >= 2 and windowEventData[3] <= (2 + 7) then
            window:set(2, 7, colors.orange, colors.white, " cancel ")
            event.sleep(0.05)
            return false
        end
    end
end