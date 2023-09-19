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
        local x, y = window:toRealPos((window.sizeX // 2) - 24, (window.sizeY // 2) - 7)

        local loadedLibraries = {}
        for name, data in pairs(package.loaded) do
            table.insert(loadedLibraries, gui_container.shortPath(name, 47))
        end
        for name, data in pairs(package.cache) do
            table.insert(loadedLibraries, gui_container.shortPath(name .. " (unloaded)", 47))
        end
        table.sort(loadedLibraries)
        local _, lscroll = gui_select(screen, x, y, "loaded libraries", loadedLibraries, scroll, true)
        scroll = lscroll
    end
end)
selector:resume()

return function(eventData)
    
end, function ()
    selector:kill()
end