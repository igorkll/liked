local graphic = require("graphic")
local event = require("event")
local gui_container = require("gui_container")
local calls = require("calls")
local unicode = require("unicode")
local fs = require("filesystem")
local liked = require("liked")
local component = require("component")

local colors = gui_container.colors
local screen = ...
local gpu = graphic.findGpu(screen)
local rx, ry = gpu.getResolution()

liked.drawUpBarTask(screen, true, colors.gray)

--------------------------------------------

local statusWindow = graphic.createWindow(screen, 1, 1, rx, 1, true)
local window = graphic.createWindow(screen, 1, 2, rx, ry - 1, true)

local function update()
    statusWindow:clear(colors.gray)
    window:clear(colors.white)
    statusWindow:set(rx, 1, colors.red, colors.white, "X")
    statusWindow:set(1, 1, colors.red, colors.white, "<")
    
    statusWindow:set(3, 1, colors.gray, colors.white, "List Of Components")

    local types = {}
    local added = {}
    for addr, ctype in component.list() do
        if not added[ctype] then
            table.insert(types, ctype)
            added[ctype] = true
        end
    end
    table.sort(types)

    local posY = 1
    for _, ctype in ipairs(types) do
        local addrs = {}
        for addr in component.list(ctype, true) do
            table.insert(addrs, addr)
        end
        table.sort(addrs)

        for _, addr in ipairs(addrs) do
            window:fill(1, posY, window.sizeX, 1, colors.white, colors.gray, "-")
            window:set(1, posY, colors.white, colors.red, addr)
            window:set(window.sizeX - (#ctype - 1), posY, colors.white, colors.blue, ctype)
            posY = posY + 1
        end
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