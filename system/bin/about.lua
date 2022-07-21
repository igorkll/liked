local graphic = require("graphic")
local event = require("event")
local gui_container = require("gui_container")
local computer = require("computer")
local calls = require("calls")
local unicode = require("unicode")

local colors = gui_container.colors
local screen = ...
local gpu = graphic.findGpu(screen)
local rx, ry = gpu.getResolution()

--------------------------------------------

local version = calls.call("getOSversion")

local statusWindow = graphic.classWindow:new(screen, 1, 1, rx, 1, true)
local window = graphic.classWindow:new(screen, 1, 2, rx, ry - 1, true)

local function update()
    local totalMemory = computer.totalMemory()
    local freeMemory = computer.freeMemory()

    statusWindow:clear(colors.gray)
    window:clear(colors.white)
    
    local title = "About"
    statusWindow:set((statusWindow.sizeX / 2) - (unicode.len(title) / 2), 1, colors.gray, colors.white, title)

    local strs = {
        "------------------------------------------OS",
        "distributive: liked",
        "distributive version: v" .. tostring(version),
        "------------------------------------------CORE",
        "core: likeOS",
        "core verion: " .. _COREVERSION,
        "core version id: " .. tostring(_COREVERSIONID),
        "------------------------------------------HARDWARE",
        "-----------MEMORY",
        "total memory: " .. math.floor(totalMemory / 1024),
        "free  memory: " .. math.floor(freeMemory / 1024),
        "used  memory: " .. math.floor((totalMemory - freeMemory) / 1024)
    }
    
    window:setCursor(1, 1)
    for i, v in ipairs(strs) do
        window:write(v .. "\n", colors.white, colors.black)
    end
    
    statusWindow:set(rx, 1, colors.red, colors.white, "X")
end
update()

--------------------------------------------

local closeFlag = true
local listens = {}

table.insert(listens, event.timer(2, function()
    update()
end, math.huge))
table.insert(listens, event.listen(nil, function(...)
    local statusWindowEventData = statusWindow:uploadEvent({...})
    if statusWindowEventData[1] == "touch" and statusWindowEventData[3] == window.sizeX and statusWindowEventData[4] == 1 then
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
    offTimers()
    closeFlag = false
end

--------------------------------------------

while closeFlag do
    event.sleep(0.1)
end