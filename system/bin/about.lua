local graphic = require("graphic")
local event = require("event")
local gui_container = require("gui_container")
local computer = require("computer")
local calls = require("calls")
local thread = require("thread")

local colors = gui_container.colors
local screen = ...
local gpu = graphic.findGpu(screen)
local rx, ry = gpu.getResolution()
local t = thread.current()

--------------------------------------------

local window = graphic.classWindow:new(screen, 1, 1, rx, ry, true)

local function update()
    local totalMemory = computer.totalMemory()
    local beforeGarbageCollector = computer.freeMemory()
    for i = 1, 5 do
        --event.sleep(0.1)
    end
    local afterGarbageCollector = computer.freeMemory()

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
        "total memory: " .. math.floor(totalMemory / 1024),
        "----before collecting garbage",
        "free  memory: " .. math.floor(beforeGarbageCollector / 1024),
        "used  memory: " .. math.floor((totalMemory - beforeGarbageCollector) / 1024),
        "----after collecting garbage",
        "free  memory: " .. math.floor(afterGarbageCollector / 1024),
        "used  memory: " .. math.floor((totalMemory - afterGarbageCollector) / 1024)
    }
    
    window:setCursor(1, 1)
    for i, v in ipairs(strs) do
        window:write(v .. "\n", colors.white, colors.black)
    end
    
    window:set(rx, 1, colors.red, colors.white, "X")
end
update()

--------------------------------------------

local closeFlag = true
local listens = {}

local function check()
    if t:status() == "dead" then
        exit()
        return true
    end
end

table.insert(listens, event.timer(2, function()
    if check() then return false end
    update()
end, math.huge))
table.insert(listens, event.listen(nil, function(...)
    if check() then return false end
    local windowEventData = window:uploadEvent({...})
    if windowEventData[1] == "touch" and windowEventData[3] == window.sizeX and windowEventData[4] == 1 then
        exit()
    end
end))

function offTimers()
    for i, v in ipairs(listens) do
        event.cancel(v)
    end
    listens = {}
end

function exit()
    closeFlag = false
    offTimers()
end

--------------------------------------------

while closeFlag do
    event.sleep(1)
end