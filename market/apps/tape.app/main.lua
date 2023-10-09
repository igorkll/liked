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

layout:createText(2, 7, nil, "loop: ")
local loopMode = layout:createSwitch(8, 7, false)

function loopMode:onSwitch() --сделай фоновый режим для loopmode
    
end

local playButton = layout:createButton(2, 3, 16, 1, nil, nil, "PLAY")
local stopButton = layout:createButton(2, 5, 16, 1, nil, nil, "STOP")
local playLed = layout:createLabel(15, 7, 3, 1)
local seekBar = layout:createSeek(2, ry - 1, rx - 2)

local writeButton = layout:createButton(19, 5, 16, 1, nil, nil, "WRITE FILE")

layout:createText(2, ry - 5, nil, "volume: ")
layout:createText(2, ry - 3, nil, "speed : ")

local volBar = layout:createSeek(10, ry - 5, rx - 10, nil, nil, nil, 0.5)
local speedBar = layout:createSeek(10, ry - 3, rx - 10, nil, nil, nil, 0.5)

function playButton:onClick()
    tape.play()
end

function stopButton:onClick()
    tape.stop()
end

------------------------------

local oldReady
local oldPlay

local function doTape()
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

    local size = tape.getSize()
    local state = tape.getState()
    local playing = state == "PLAYING"

    if playing then
        if seekBar.focus then
            tape.seek((seekBar.value * size) - tape.getPosition())
        else
            seekBar.value = tape.getPosition() / size
            seekBar:draw()
        end
    end

    if playing ~= oldPlay then
        if playing then
            playLed.back = colors.yellow
            playLed:draw()
        else
            playLed.back = colors.gray
            playLed:draw()
        end

        oldPlay = playing
    end

    if loopMode.state and tape.isEnd() then
        tape.seek(-size)
        tape.play()
        seekBar.value = 0
        seekBar:draw()
    end

    tape.setVolume(volBar.value)
    tape.setSpeed(speedBar.value * 2)
end

thread.create(function ()
    while true do
        doTape()
        os.sleep(0.1)
    end
end):resume()

local function redraw()
    doTape()
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