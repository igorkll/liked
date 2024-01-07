local graphic = require("graphic")
local gui_container = require("gui_container")
local registry = require("registry")
local apps = require("apps")
local thread = require("thread")

local colors = gui_container.colors

------------------------------------

local screen, posX, posY = ...
local rx, ry = graphic.getResolution(screen)
local window = graphic.createWindow(screen, posX, posY, rx - (posX - 1), ry - (posY - 1))

local th = thread.create(function ()
    assert(apps.execute("/system/bin/setup.app/inet.lua", screen, nil, window))
end)
th:resume()

return function(eventData)
end, function ()
    th:kill()
end