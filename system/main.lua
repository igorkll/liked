local graphic = require("graphic")
local component = require("component")
local computer = require("computer")
local event = require("event")
local calls = require("calls")
local unicode = require("unicode")
local gui_container = require("gui_container")

local colors = gui_container.colors

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

    window:set(2, 1, colors.gray, colors.white, "OS")
end
draw()

while true do
    local eventData = {event.pull()}
    local windowEventData = window:uploadEvent(eventData)
    if windowEventData[1] == "touch" then
        if windowEventData[4] == 1 and windowEventData[3] >= 2 and windowEventData[3] <= 3 then
            local str, num = calls.call("gui_context", screen, 2, 2,
            {"  about", "  read", "  menu           >", "------------------", "  shutdown", "  reboot"},
            {true, true, true, false, true, true})
            if num == 1 then
                --calls.call("gui_warn", screen, nil, nil, "about is not found")
                for i = 1, 5 do computer.pullSignal(0.2) end
                local free = computer.freeMemory()

                calls.call("gui_warn", screen, nil, nil, "memory: " .. tostring(math.floor(computer.totalMemory() / 1024)) .. "kb")
                draw()

                calls.call("gui_warn", screen, nil, nil, "free memory: " .. tostring(math.floor(free / 1024)) .. "kb")
                draw()

                calls.call("gui_warn", screen, nil, nil, "used memory: " .. tostring(math.floor((computer.totalMemory() - free) / 1024)) .. "kb")
                draw()
            elseif num == 2 then
                local data = calls.call("gui_input", screen, nil, nil, "enter data")
                if data and data ~= true then
                    calls.call("gui_warn", screen, nil, nil, "data: " .. data)
                end
            elseif num == 3 then
                local str, num = calls.call("gui_context", screen, 20, 3,
                {"beep 2000", "beep 1000"})
                if str then
                    if calls.call("gui_yesno", screen, nil, nil, str .. "?") then
                        if num == 1 then
                            computer.beep(2000)
                        elseif num == 2 then
                            computer.beep(1000)
                        end
                    end
                end
            elseif num == 5 then
                computer.shutdown()
            elseif num == 6 then
                computer.shutdown(true)
            end
            draw()
        end
    end
end

--[[
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
]]