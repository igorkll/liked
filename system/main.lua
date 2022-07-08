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
calls.call("gui_initScreen", screen)
local rx, ry = graphic.findGpu(screen).getResolution()

local statusWindow = graphic.classWindow:new(screen, 1, 1, rx, 1)
local window = graphic.classWindow:new(screen, 1, 2, rx, ry)

------------------------------------

local function drawStatus()
    local hours, minutes, seconds = calls.call("getRealTime", 3)
    hours = tostring(hours)
    minutes = tostring(minutes)
    if #hours == 1 then hours = "0" .. hours end
    if #minutes == 1 then minutes = "0" .. minutes end
    local str = hours .. ":" .. minutes

    statusWindow:fill(1, 1, rx, 1, colors.gray, 0, " ")
    statusWindow:set(window.sizeX - unicode.len(str), 1, colors.gray, colors.white, str)
    statusWindow:set(1, 1, colors.lightGray, colors.white, " OS ")
end
local function draw()
    drawStatus()
    window:clear(colors.lightBlue)
    calls.call("gui_drawimage", screen, "/image.t2p", window:toRealPos(16, 8))
end
draw()

------------------------------------

local statusTimer
local function startStatusTimer()
    statusTimer = event.timer(10, function()
        drawStatus()
    end, math.huge)
end
local function stopStatusTimer()
    event.cancel(statusTimer)
end
startStatusTimer()

------------------------------------

local function execute(name)
    stopStatusTimer()
    local ok, err = programs.execute(name)
    startStatusTimer()
    draw()
    if not ok then
        calls.call("gui_warn", screen, nil, nil, err or "unknown error")
    end
end

while true do
    local eventData = {event.pull()}
    local windowEventData = window:uploadEvent(eventData)
    local statusWindowEventData = statusWindow:uploadEvent(eventData)
    if statusWindowEventData[1] == "touch" then
        if statusWindowEventData[4] == 1 and statusWindowEventData[3] >= 1 and statusWindowEventData[3] <= 4 then
            local str, num = calls.call("gui_context", screen, 2, 2,
            {"  about", "------------------", "  shutdown", "  reboot"},
            {true, false, true, true})
            if num == 1 then
                execute("about")
            elseif num == 3 then
                computer.shutdown()
            elseif num == 4 then
                computer.shutdown(true)
            end
            draw()
        end
    end
end