local graphic = require("graphic")
local uix = require("uix")
local gobjs = require("gobjs")
local autorun = require("autorun")
local paths = require("paths")

local colors = uix.colors

------------------------------------

local screen, posX, posY = ...
local gpu = graphic.findGpu(screen)
local rx, ry = gpu.getResolution()

------------------------------------

local window = graphic.createWindow(screen, posX, posY, rx - (posX - 1), ry - (posY - 1))
local layout = uix.create(window)
layout:createText(2, 2, colors.white, "autorun scripts:")
local autorunList = layout:createCustom(2, 4, gobjs.checkboxgroup, window.sizeX - 25, window.sizeY - 5)
for _, item in ipairs(autorun.list("user")) do
    table.insert(autorunList.list, {paths.hideExtension(paths.name(item[1])), item[2]})
end
layout:draw()

return function(eventData)
    local windowEventData = window:uploadEvent(eventData)
    layout:uploadEvent(windowEventData)
end