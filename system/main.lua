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

    calls.call("gui_warn", screen, "memory: " .. tostring(math.floor(computer.totalMemory() / 1024)) .. "kb")
    window:clear(0x000000)

    calls.call("gui_warn", screen, "free memory: " .. tostring(math.floor(computer.freeMemory() / 1024)) .. "kb")
    window:clear(0x000000)

    calls.call("gui_warn", screen, "used memory: " .. tostring(math.floor((computer.totalMemory() - computer.freeMemory()) / 1024)) .. "kb")
    window:clear(0x000000)

    if calls.call("gui_yesno", screen, "beep 2000?") then
        computer.beep(2000)
    else
        computer.beep(1000)
    end

    window:clear(0x000000)

    local _, num = calls.call("gui_context", screen, 18, 8,
    {"  beep 2000         ", "  beep 1000         ", "-----------------------", "  beep 200          ", "  beep 100          "},
    {true, true, false, false, true})
    if num then
        if num == 1 then
            computer.beep(2000)
        elseif num == 2 then
            computer.beep(1000)
        elseif num == 4 then
            computer.beep(200)
        elseif num == 5 then
            computer.beep(100)
        end
    end
end
