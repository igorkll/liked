local thread = require("thread")
local graphic = require("graphic")
local uix = require("uix")
local event = require("event")
local gui_container = require("gui_container")
local colorslib = require("colors")
local system = require("system")
local paths = require("paths")
local time = require("time")

local appfolder = paths.path(system.getSelfScriptPath())
local watchIcon = paths.concat(appfolder, "watch.t2p")
local compassIcon = paths.concat(appfolder, "compass.t2p")
local colors = gui_container.colors

local screen = ...
local rx, ry = graphic.getResolution(screen)
local window = graphic.createWindow(screen, 1, 1, rx, ry)
local layout = uix.create(window, colors.black)
layout:createAutoUpBar("Tool Box")

--------------------------------------- watch

local watchCls = {}

function watchCls:onCreate()
    self.image = layout:createImage(self.x, self.y, watchIcon)
end

function watchCls:onDestroy()
    self.image:destroy()
end

function watchCls:draw()
    
end

--------------------------------------- compass

---------------------------------------

layout:createCustom(2, 3, watchCls)
layout:createCustom(50, 3, watchCls)
layout:draw()

while true do
    local eventData = {event.pull()}
    layout:uploadEvent(eventData)
end