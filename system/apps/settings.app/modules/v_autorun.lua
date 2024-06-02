local graphic = require("graphic")
local uix = require("uix")
local gobjs = require("gobjs")
local autorun = require("autorun")
local paths = require("paths")
local iowindows = require("iowindows")
local gui = require("gui")

local colors = uix.colors

------------------------------------

local screen, posX, posY = ...
local gpu = graphic.findGpu(screen)
local rx, ry = gpu.getResolution()

------------------------------------

local window = graphic.createWindow(screen, posX, posY, rx - (posX - 1), ry - (posY - 1))
local layout = uix.create(window, colors.black)

local function redraw()
    gRedraw()
    layout:draw()
end

layout:createText(2, 2, colors.white, "autorun scripts:")
local autorunScriptsListSizeX = window.sizeX - 25
local autorunList = layout:createCustom(2, 4, gobjs.checkboxgroup, autorunScriptsListSizeX, window.sizeY - 6)
local function refreshList()
    autorun.check()
    autorunList.list = {}
    for _, item in ipairs(autorun.list("user")) do
        table.insert(autorunList.list, 1, {gui.fpath(screen, item[1], autorunList.sizeX - 3), item[2]})
    end
end
refreshList()

local addScriptButton = layout:createButton(2, window.sizeY - 1, autorunScriptsListSizeX, 1, nil, nil, "add script to autorun")
function addScriptButton:onDrop()
    local scriptPath = iowindows.selectfile(screen, "lua")
    if scriptPath then
        autorun.reg("user", scriptPath)
        refreshList()
    end
    redraw()
end

redraw()

return function(eventData)
    local windowEventData = window:uploadEvent(eventData)
    layout:uploadEvent(windowEventData)
end