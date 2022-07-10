local graphic = require("graphic")
local fs = require("filesystem")
local gui_container = require("gui_container")

local colors = gui_container.colors

------------------------------------

local screen = ...
local gpu = graphic.findGpu(screen)
local rx, ry = gpu.getResolution()

local statuswindow = graphic.classWindow:new(1, 1, rx, 1)
local mainwindow = graphic.classWindow:new(1, 2, rx, ry - 1)

------------------------------------

local function draw()
    statuswindow:clear(colors.gray)
    mainwindow:clear(colors.lightGray)

    statuswindow:set(1, 1, colors.red, colors.white, "X")
    statuswindow:set(rx - 5, 1, colors.gray, colors.white, "paint")

    statuswindow:set(3, 1, colors.white, colors.black, "file")
    statuswindow:set(8, 1, colors.white, colors.black, "settings")
end

while true do
    
end