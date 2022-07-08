local graphic = require("graphic")
local event = require("event")
local gui_container = require("gui_container")
local computer = require("computer")
local calls = require("calls")

local colors = gui_container.colors
local screen = gui_container.screen
local gpu = graphic.findGpu(screen)
local rx, ry = gpu.getResolution()

--------------------------------------------

local window = graphic.classWindow:new(screen, 1, 1, rx, ry, true)

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



local listens = {}

local function offTimers()
    for i, v in ipairs(listens) do
        event.cancel(v)
    end
    listens = {}
end

local closeFlag = false
local function exit()
    closeFlag = true
    offTimers()
end

local function onTimers()
    table.insert(listens, event.timer(2, function()
        update()
    end, math.huge))
    table.insert(listens, event.listen(nil, function(...)
        local windowEventData = window:uploadEvent(...)
        if windowEventData[1] == "touch" and windowEventData[3] == rx and windowEventData[4] == 1 then
            exit()
            break
        end
    end))
end
onTimers()

--------------------------------------------

while closeFlag do
    event.sleep(1)
end