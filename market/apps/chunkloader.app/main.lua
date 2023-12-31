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
local gui = require("gui")

local appfolder = paths.path(system.getSelfScriptPath())
local colors = gui_container.colors

local screen = ...

local chunkloader = gui.selectcomponentProxy(screen, nil, nil, "chunkloader", true)
if not chunkloader then return end

local rx, ry = graphic.getResolution(screen)
local window = graphic.createWindow(screen, 1, 1, rx, ry)
local layout = uix.create(window, colors.black)
local up = layout:createAutoUpBar("Chunkloader")

---------------------------------------

local switch = layout:createBigSwitch((rx / 2) - 7, ry <= 16 and 1 or 6, chunkloader.isActive())

function switch:onSwitch()
    chunkloader.setActive(self.state)
    up:draw()
end

layout:draw()
up:draw()

while true do
    local eventData = {event.pull()}
    layout:uploadEvent(eventData)
end