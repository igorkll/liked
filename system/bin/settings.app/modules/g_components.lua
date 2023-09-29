local graphic = require("graphic")
local gui_container = require("gui_container")
local thread = require("thread")
local component = require("component")
local system = require("system")

local colors = gui_container.colors

------------------------------------

local screen, posX, posY = ...
local gpu = graphic.findGpu(screen)
local rx, ry = gpu.getResolution()

------------------------------------

local window = graphic.createWindow(screen, posX, posY, rx - (posX - 1), ry - (posY - 1))

------------------------------------

local function drawInfo()
    local currentCount = 0
    for addr in component.list() do
        currentCount = currentCount + 1
    end
    currentCount = currentCount - 3
    window:set(2, 2, colors.brown, colors.white, "component count: " .. math.floor(system.getCurrentComponentCount()) .. "/" .. system.getMaxComponentCount() .. "    ")
end

local componentSelector = thread.create(function ()
    while true do
        window:clear(colors.brown)
        drawInfo()

        local x, y = window:toRealPos((window.sizeX // 2) - 27, (window.sizeY // 2) - 8)
        gui_selectcomponent(screen, x, y, nil, nil, true)
    end
end)
componentSelector:resume()

return function(eventData)
    if eventData[1] == "component_added" or eventData[1] == "component_removed" then
        drawInfo()
    end
end, function ()
    componentSelector:kill()
end