local graphic = require("graphic")
local component = require("component")
local computer = require("computer")
local event = require("event")
local calls = require("calls")

------------------------------------

local screen = "20108ef5-444e-46bc-bd6c-48aee518009e"
calls.call("initScreen", screen)
local rx, ry = graphic.findGpu(screen).getResolution()

local window = graphic.classWindow:new(screen, 1, 1, rx, ry)

while true do
    window:clear(0x000000)
    calls.call("gui_warn", screen, "asdasd")
    window:clear(0x000000)
    if calls.call("gui_yesno", screen, "beep 2000?") then
        computer.beep(2000)
    else
        computer.beep(1000)
    end
end
