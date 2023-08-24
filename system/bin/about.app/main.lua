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

local title = "About"

--------------------------------------------

local deviceType = getDeviceType()

local hddTotalSpace = fs.get("/").spaceTotal()
local hddUsedSpace = fs.get("/").spaceUsed()

local statusWindow = graphic.createWindow(screen, 1, 1, rx, 1, true)
local window = graphic.createWindow(screen, 1, 2, rx, ry - 1, true)

local function progressBar(y, value, firstColor, seconderyColor)
    for i = 6, window.sizeX - 1 do
        local lvalue = (i - 6) / (window.sizeX - 1)
        window:set(i, y, lvalue < value and firstColor or seconderyColor, 0, " ")
    end
end

local function insertText(x, y, color, text)
    while #text > 0 do
        local char, fore, back = window:get(x, y)
        window:set(x, y, back, color, text:sub(1, 1))
        x = x + 1
        text = text:sub(2, #text)
    end
end

local function update()
    local totalMemory = computer.totalMemory()
    local freeMemory = computer.freeMemory()

    statusWindow:clear(colors.gray)
    statusWindow:set((statusWindow.sizeX / 2) - (unicode.len(title) / 2), 1, colors.gray, colors.white, title)
    statusWindow:set(rx, 1, colors.red, colors.white, "X")

    local hddUsedValue = hddUsedSpace / hddTotalSpace
    local ramUsedValue = 1 - (freeMemory / totalMemory)

    --[[
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
        "used  memory: " .. math.round(ramUsedValue * 100) .. "%",
        "-----------MEMORY(HDD)",
        "hdd address : " .. fs.bootaddress,
        "total memory: " .. math.round(hddTotalSpace / 1024) .. "kb",
        "free  memory: " .. math.round((hddTotalSpace - hddUsedSpace) / 1024) .. "kb",
        "used  memory: " .. math.round(hddUsedSpace / 1024) .. "kb",
        "used  memory: " .. math.round(hddUsedValue * 100) .. "%",
    }
    ]]
    
    window:clear(colors.white)
    window:set(2, 2, colors.white, colors.black, "Operating System : " .. tostring(_OSVERSION) .. " / " .. tostring(_COREVERSION))
    window:set(2, 3, colors.white, colors.black, "Computer Address : " .. computer.address())
    window:set(2, 4, colors.white, colors.black, "Boot Disk        : " .. fs.bootaddress)
    window:set(2, 5, colors.white, colors.black, "Device Type      : " .. deviceType)
    window:set(2, 7, colors.blue, colors.white, "List Of Components")

    window:set(2, window.sizeY - 2, colors.white, colors.black, "ROM")
    progressBar(window.sizeY - 2, hddUsedValue, colors.lime, colors.green)
    insertText(8, window.sizeY - 2, colors.white, math.round(hddUsedSpace / 1024) .. "kb / " .. math.round(hddTotalSpace / 1024) .. "kb")

    window:set(2, window.sizeY - 1, colors.white, colors.black, "RAM")
    progressBar(window.sizeY - 1, ramUsedValue, colors.lightBlue, colors.blue)
    insertText(8, window.sizeY - 1, colors.white, math.round((totalMemory - freeMemory) / 1024) .. "kb / " .. math.round(totalMemory / 1024) .. "kb")
end
update()

--------------------------------------------

local oldtime = computer.uptime()

while true do
    local eventData = {computer.pullSignal(0.5)}

    local statusWindowEventData = statusWindow:uploadEvent(eventData)
    if statusWindowEventData[1] == "touch" and statusWindowEventData[3] == window.sizeX and statusWindowEventData[4] == 1 then
        break
    end

    local windowEventData = window:uploadEvent(eventData)
    if windowEventData[1] == "touch" and windowEventData[3] >= 2 and windowEventData[3] <= 19 and windowEventData[4] == 7 then
        local result = {programs.execute(paths.concat(paths.path(getPath()), "componentlist.lua"), screen)}
        assert(table.unpack(result))
        if result[1] and result[2] then
            break
        end
    end

    if computer.uptime() - oldtime > 1 then
        oldtime = computer.uptime()
        update()
    end
end