local graphic = require("graphic")
local event = require("event")
local gui_container = require("gui_container")
local computer = require("computer")

local colors = gui_container.colors
local screen = gui_container.screen
local gpu = graphic.findGpu(screen)
local rx, ry = gpu.getResolution()

--------------------------------------------

local window = graphic.classWindow:new(screen, 1, 2, rx, ry - 1, true)

local function update()
    for i = 1, 5 do
        event.sleep(0.1)
    end

    window:clear(colors.white)

    local strs = {
        "OS INFO",
        "------------------------------------------OS",
        "distributive: liked",
        "distributive version: v0.1",
        "------------------------------------------CORE",
        "OS core: likeOS",
        "core verion: " .. _COREVERSION,
        "core version id: " .. tostring(_COREVERSIONID),
        "------------------------------------------HARDWARE",
        "total memory: " .. math.floor(computer.totalMemory() / 1024),
        "free  memory: " .. math.floor(computer.freeMemory() / 1024),
        "used  memory: " .. math.floor((computer.totalMemory() - computer.freeMemory()) / 1024)
    }
    
    window:setCursor(1, 1)
    for i, v in ipairs(strs) do
        window:write(v .. "\n", colors.white, colors.black)
    end
    
    window:set(rx, 1, colors.red, colors.white, "X")
end
update()

--------------------------------------------

local timers = {}
local function offTimers()
    for i, v in ipairs(timers) do
        event.cancel(v)
    end
    timers = {}
end
local function onTimers()
    table.insert(timers, event.timer(2, function()
        update()
    end, math.huge))
end
onTimers()

local watchdog = event.listen("redraw", function(_, state)
    if state then
        onTimers()
    else
        offTimers()
    end
end)

local function exit()
    offTimers()
    event.cancel(watchdog)
end

--------------------------------------------

while true do
    local eventData = {event.pull(0.5)}
    local windowEventData = window:uploadEvent(eventData)
    if windowEventData[1] == "touch" and windowEventData[3] == rx and windowEventData[4] == 1 then
        exit()
        break
    end
    if eventData[1] == "closePressed" then
        exit()
        break
    end
end