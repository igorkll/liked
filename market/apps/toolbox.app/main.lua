local thread = require("thread")
local graphic = require("graphic")
local uix = require("uix")
local event = require("event")
local component = require("component")
local gui_container = require("gui_container")
local colorslib = require("colors")
local system = require("system")
local paths = require("paths")
local time = require("time")
local thread = require("thread")

local appfolder = paths.path(system.getSelfScriptPath())
local watchIcon = paths.concat(appfolder, "watch.t2p")
local compassIcon = paths.concat(appfolder, "compass.t2p")
local imgX, imgY = 26, 16
local colors = gui_container.colors

local screen = ...
local rx, ry = graphic.getResolution(screen)
local window = graphic.createWindow(screen, 1, 1, rx, ry)
local draw = require("draw").create(window)
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

function watchCls:onDraw()
    
end

--------------------------------------- compass

local compassCls = {}

function compassCls:onCreate()
    self.image = layout:createImage(self.x, self.y, compassIcon)
end

function compassCls:onDestroy()
    self.image:destroy()
end

function compassCls:onDraw()
    if component.tablet then
        local x, y = self.x + (imgX / 2), self.y + (imgY / 2)
        local rad = math.rad(-(component.tablet.getYaw()))
        draw:line(x, y, x + (math.sin(rad) * 6), y + (math.cos(rad) * 6), colors.red)
    end
end

---------------------------------------

layout:createCustom(2, 6, watchCls)
layout:createCustom(55, 6, compassCls)
layout:draw()

thread.create(function ()
    while true do
        layout:draw()
        os.sleep(0.5)
    end
end):resume()

while true do
    local eventData = {event.pull()}
    layout:uploadEvent(eventData)
end