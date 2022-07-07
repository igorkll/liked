local graphic = require("graphic")
local component = require("component")
local computer = require("computer")
local event = require("event")
local calls = require("calls")
local unicode = require("unicode")
local programs = require("programs")
local gui_container = require("gui_container")

local colors = gui_container.colors

------------------------------------

local screen = gui_container.screen
calls.call("initScreen", screen)
local rx, ry = graphic.findGpu(screen).getResolution()

local statusWindow = graphic.classWindow:new(screen, 1, 1, rx, 1)
local window = graphic.classWindow:new(screen, 1, 2, rx, ry)

local function drawStatus()
    local hours, minutes, seconds = calls.call("getRealTime", 3)
    hours = tostring(hours)
    minutes = tostring(minutes)
    if #hours == 1 then hours = "0" .. hours end
    if #minutes == 1 then minutes = "0" .. minutes end
    local str = hours .. ":" .. minutes

    statusWindow:fill(1, 1, rx, 1, colors.gray, 0, " ")
    statusWindow:set(window.sizeX - unicode.len(str), 1, colors.gray, colors.white, str)
    statusWindow:set(2, 1, colors.gray, colors.white, "OS")
end

local function draw()
    drawStatus()
    window:clear(colors.lightBlue)
end
draw()

event.timer(10, function()
    drawStatus()
end, math.huge)



while true do
    local eventData = {event.pull()}
    local windowEventData = window:uploadEvent(eventData)
    local statusWindowEventData = statusWindow:uploadEvent(eventData)
    if statusWindowEventData[1] == "touch" then
        if statusWindowEventData[4] == 1 and statusWindowEventData[3] >= 2 and statusWindowEventData[3] <= 3 then
            local str, num = calls.call("gui_context", screen, 2, 2,
            {"  about", "------------------", "  shutdown", "  reboot"},
            {true, false, true, true})
            if num == 1 then
                local id
                local function checkFunc(...)
                    local statusWindowEventData = statusWindow:uploadEvent(...)
                    if statusWindowEventData[4] == 1 and statusWindowEventData[3] >= 2 and statusWindowEventData[3] <= 3 then
                        event.cancel(id)
                        local str, num = calls.call("gui_context", screen, 2, 2,
                        {"  close", "------------------", "  shutdown", "  reboot"},
                        {true, false, true, true})
                        id = event.listen("touch", checkFunc)
                        if num == 1 then
                            event.push("closePressed")
                        elseif num == 3 then
                            computer.shutdown()
                        elseif num == 4 then
                            computer.shutdown(true)
                        end
                    end
                end
                id = event.listen("touch", checkFunc)
                programs.execute("about")
                event.cancel(id)
            elseif num == 3 then
                computer.shutdown()
            elseif num == 4 then
                computer.shutdown(true)
            end
            draw()
        end
    end
end