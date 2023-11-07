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

local assembler = gui.selectcomponentProxy(screen, nil, nil, "assembler", true)
if not assembler then return end

local rx, ry = graphic.getResolution(screen)
local window = graphic.createWindow(screen, 1, 1, rx, ry)
local layout = uix.create(window, colors.black)
layout:createAutoUpBar("Assembler")

---------------------------------------

local statusLabel = layout:createLabel((rx / 2) - 7, (ry / 2) - 3, 16, 1)
local startButton = layout:createButton((rx / 2) - 7, (ry / 2) + 2, 16, 3, nil, nil, "Start")
local progressBar = layout:createProgress(2, ry - 1, rx - 2)
local allowStart = false
local oldAllowStart

function startButton:onClick()
    if allowStart then
        local ok = assembler.start()
        if not ok then
            gui.warn(screen, nil, nil, "failed to start the assembly")
            layout:draw()
        end
    end
end

local function reloadStatus()
    local status, allow = assembler.status()
    if type(allow) == "boolean" then
        allowStart = allow
        local value = 0
        if progressBar.value ~= value then
            progressBar.value = value
            progressBar:draw()
        end
    else
        allowStart = false
        if type(allow) == "number" then
            local value = allow / 100
            if progressBar.value ~= value then
                progressBar.value = value
                progressBar:draw()
            end
        end
    end
    if allowStart ~= oldAllowStart then
        if allowStart then
            startButton.back = colors.white
            startButton.fore = colors.gray
            startButton.back2 = startButton.fore
            startButton.fore2 = startButton.back
            startButton.disabled = false
        else
            startButton.back = colors.lightGray
            startButton.fore = colors.gray
            startButton.back2 = startButton.fore
            startButton.fore2 = startButton.back
            startButton.disabled = true
        end
        startButton:draw()
        oldAllowStart = allowStart
    end

    if status ~= statusLabel.text then
        statusLabel.text = status
        statusLabel:draw()
    end
end

reloadStatus()
layout:draw()

while true do
    local eventData = {event.pull(0.5)}
    layout:uploadEvent(eventData)
    reloadStatus()
end