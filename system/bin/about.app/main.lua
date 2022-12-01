local graphic = require("graphic")
local event = require("event")
local gui_container = require("gui_container")
local computer = require("computer")
local calls = require("calls")
local unicode = require("unicode")
local fs = require("filesystem")
local paths = require("paths")
local programs = require("programs")

local colors = gui_container.colors
local screen = ...
local gpu = graphic.findGpu(screen)
local rx, ry = gpu.getResolution()

--------------------------------------------

local version = calls.call("getOSversion")
local hddTotalSpace = fs.get("/").spaceTotal()
local hddUsedSpace = fs.get("/").spaceUsed()

local statusWindow = graphic.createWindow(screen, 1, 1, rx, 1, true)
local window = graphic.createWindow(screen, 1, 2, rx, ry - 1, true)

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
        "------------------------------------------HARDWARE",
        "-----------MAIN",
        "device type: " .. getDeviceType(),
        "-----------MEMORY(RAM)",
        "total memory: " .. math.round(totalMemory / 1024) .. "kb",
        "free  memory: " .. math.round(freeMemory / 1024) .. "kb",
        "used  memory: " .. math.round((totalMemory - freeMemory) / 1024) .. "kb",
        "used  memory: " .. math.round((1 - (freeMemory / totalMemory)) * 100) .. "%",
        "-----------MEMORY(HDD)",
        "hdd address : " .. fs.bootaddress,
        "total memory: " .. math.round(hddTotalSpace / 1024) .. "kb",
        "free  memory: " .. math.round((hddTotalSpace - hddUsedSpace) / 1024) .. "kb",
        "used  memory: " .. math.round(hddUsedSpace / 1024) .. "kb",
        "used  memory: " .. math.round((hddUsedSpace / hddTotalSpace) * 100) .. "%",
    }
    
    window:setCursor(1, 1)
    for i, v in ipairs(strs) do
        window:write(v .. "\n", colors.white, colors.black)
    end
    
    statusWindow:set(rx, 1, colors.red, colors.white, "X")

    window:set(1, window.sizeY, colors.blue, colors.white, "list of components")
end
update()

--------------------------------------------

local oldtime = computer.uptime()

while true do
    local eventData = {event.pull(0.5)}

    local statusWindowEventData = statusWindow:uploadEvent(eventData)
    if statusWindowEventData[1] == "touch" and statusWindowEventData[3] == window.sizeX and statusWindowEventData[4] == 1 then
        break
    end

    local windowEventData = window:uploadEvent(eventData)
    if windowEventData[1] == "touch" and windowEventData[3] >= 1 and windowEventData[3] <= 18 and windowEventData[4] == window.sizeY then
        assert(programs.execute(paths.concat(paths.path(getPath()), "componentlist.lua"), screen))
        update()
    end

    if computer.uptime() - oldtime > 1 then
        oldtime = computer.uptime()
        update()
    end
end