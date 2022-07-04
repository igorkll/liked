local graphic = require("graphic")
local component = require("component")
local computer = require("computer")
local event = require("event")
local calls = require("calls")
local explorer = require("explorer")

local colors = explorer.colors

------------------------------------

local screen = "20108ef5-444e-46bc-bd6c-48aee518009e"
calls.call("initScreen", screen)
local rx, ry = graphic.findGpu(screen).getResolution()

local window = graphic.classWindow:new(screen, 1, 1, rx, ry)

local function draw()
    window:clear(colors.lightBlue)
    window:fill(1, 1, rx, 1, colors.gray, 0, " ")

    local str = "12:00"
    window:set(window.sizeX - unicode.len(str), 1, colors.gray, colors.white, str)

    window:set(1, 1, colors.gray, colors.white, "OS")
end
draw()

while true do
    local eventData = {event.pull()}
    local windowEventData = window:uploadEvent(eventData)
    if windowEventData[1] == "touch" then
        if windowEventData[4] == 1 and windowEventData[3] >= 1 and windowEventData[3] <= 2 then
            local str, num = calls.call("gui_context", screen, 2, 2,
            {"shutdown", "reboot"})
            if num == 1 then
                computer.shutdown()
            elseif num == 2 then
                computer.shutdown(true)
            end
            draw()
        end
    end
end

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
