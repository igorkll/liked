local graphic = require("graphic")
local gui_container = require("gui_container")
local package = require("package")
local thread = require("thread")

local colors = gui_container.colors

------------------------------------

local screen, posX, posY = ...
local gpu = graphic.findGpu(screen)
local rx, ry = gpu.getResolution()

------------------------------------

local window = graphic.createWindow(screen, posX, posY, rx - (posX - 1), ry - (posY - 1))

------------------------------------

local selector = thread.create(function ()
    local scroll
    while true do
        window:clear(colors.brown)
        local x, y = window:toRealPos((window.sizeX // 2) - 27, (window.sizeY // 2) - 6)

        local loadedLibraries = {}
        local constCount = 0
        local unloadableCount = 0
        for name, data in pairs(package.loaded) do
            table.insert(loadedLibraries, gui_container.short(name, 47))
            constCount = constCount + 1
        end
        for name, data in pairs(package.cache) do
            table.insert(loadedLibraries, gui_container.short(name .. " (unloadable)", 47))
            unloadableCount = unloadableCount + 1
        end
        table.sort(loadedLibraries)

        window:set(2, 2, colors.brown, colors.white, "total      count: " .. math.round(constCount + unloadableCount))
        window:set(2, 3, colors.brown, colors.white, "static     count: " .. math.round(constCount))
        window:set(2, 4, colors.brown, colors.white, "unloadable count: " .. math.round(unloadableCount))

        local _, lscroll = gui_select(screen, x, y, "loaded libraries", loadedLibraries, scroll, true)
        scroll = lscroll
    end
end)
selector:resume()

return function(eventData)
    
end, function ()
    selector:kill()
end