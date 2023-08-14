local graphic = require("graphic")
local event = require("event")
local gui_container = require("gui_container")
local computer = require("computer")
local calls = require("calls")
local unicode = require("unicode")
local fs = require("filesystem")
local programs = require("programs")
local component = require("component")

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
    statusWindow:clear(colors.gray)
    window:clear(colors.white)
    statusWindow:set(rx, 1, colors.red, colors.white, "X")
    statusWindow:set(1, 1, colors.red, colors.white, "<")
    
    local title = "List Of Components"
    statusWindow:set((statusWindow.sizeX / 2) - (unicode.len(title) / 2), 1, colors.gray, colors.white, title)

    local posY = 1
    for address, ctype in component.list() do
        window:fill(1, posY, window.sizeX, 1, colors.white, colors.gray, "-")
        window:set(1, posY, colors.white, colors.red, address)
        window:set(window.sizeX - (#ctype - 1), posY, colors.white, colors.blue, ctype)
        posY = posY + 1
    end
end
update()

--------------------------------------------

while true do
    local eventData = {event.pull()}

    local statusWindowEventData = statusWindow:uploadEvent(eventData)
    if statusWindowEventData[1] == "touch" and statusWindowEventData[3] == window.sizeX and statusWindowEventData[4] == 1 then
        return true
    end
    if statusWindowEventData[1] == "touch" and statusWindowEventData[3] == 1 and statusWindowEventData[4] == 1 then
        return
    end
end