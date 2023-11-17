local graphic = require("graphic")
local gui_container = require("gui_container")
local thread = require("thread")
local component = require("component")
local system = require("system")
local gui = require("gui")

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
    window:set(2, 2, colors.black, colors.white, "component count: " .. math.roundTo(system.getCurrentComponentCount(), 2) .. "/" .. system.getMaxComponentCount() .. "    ")
end

local base = thread.current()

local componentSelector = thread.createBackground(function ()
    while true do
        window:clear(colors.black)
        drawInfo()

        local x, y = window:toRealPos((window.sizeX // 2) - 27, (window.sizeY // 2) - 8)
        gui.selectcomponent(screen, x, y, nil, nil, true, {onEdit = function()
            base:suspend()
            upTask:suspend()
        end, onCloseEdit = function()
            base:resume()
            upTask:resume()
        end})
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