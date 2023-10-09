local graphic = require("graphic")
local uix = require("uix")
local fs = require("filesystem")
local colors = require("gui_container").colors
local gui = require("gui")
local liked = require("liked")
local component = require("component")
local event = require("event")
local thread = require("thread")

local screen, nickname, path = ...
local tape = gui.selectcomponent(screen, nil, nil, {"tape_drive"}, true)
if tape then
    tape = component.proxy(tape)
else
    return
end
local rx, ry = graphic.getResolution(screen)
local window = graphic.createWindow(screen, 1, 1, rx, ry)
local layout = uix.create(window, colors.black)

local upTh, upRedraw, upCallbacks = liked.drawFullUpBarTask(screen)

local baseTh = thread.current()
upCallbacks.exit = function ()
    baseTh:kill()
end


local tapeLabel = layout:createInput(19, 3, rx - 19, nil, nil, false, nil, nil, 32, "label: ")
function tapeLabel:onTextChanged(text)
    tape.setLabel(text)
end

local playButton = layout:createButton(2, 3, 16, 1, nil, nil, "PLAY")
local stopButton = layout:createButton(2, 5, 16, 1, nil, nil, "STOP")
local seekBar = layout:createSeek(2, ry - 5, rx - 2)

------------------------------

thread.create(function ()
    local oldReady
    while true do
        local ready = tape.isReady()
        if ready ~= oldReady then
            if ready then
                tapeLabel.read.setBuffer(tape.getLabel() or "none")
                tapeLabel.read.setLock(false)
            else
                tapeLabel.read.setBuffer("TAPE IS MISSING")
                tapeLabel.read.setLock(true)
            end
            tapeLabel:draw()
            oldReady = ready
        end
        os.sleep(1)
    end
end):resume()

local function redraw()
    if tape.isReady() then
        tapeLabel.read.setBuffer(tape.getLabel() or "none")
        tapeLabel.read.setLock(false)
    else
        tapeLabel.read.setBuffer("TAPE IS MISSING")
        tapeLabel.read.setLock(true)
    end
    layout:draw()
    upRedraw()
end
redraw()

while true do
    local eventData = {event.pull()}
    local windowEventData = window:uploadEvent(eventData)
    layout:uploadEvent(windowEventData)
end