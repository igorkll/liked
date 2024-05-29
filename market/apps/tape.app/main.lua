local graphic = require("graphic")
local uix = require("uix")
local fs = require("filesystem")
local colors = require("gui_container").colors
local gui = require("gui")
local liked = require("liked")
local component = require("component")
local event = require("event")
local thread = require("thread")
local paths = require("paths")

local screen, nickname, path = ...
local tape = gui.selectcomponent(screen, nil, nil, {"tape_drive"}, true)
if tape then
    tape = component.proxy(tape)
else
    return
end

if not _G.tape_agent then
    _G.tape_agent = {}
end

local agent = _G.tape_agent[tape.address]
if not agent then
    agent = {}
    agent.volume = 0.5
    agent.speed = 1
    agent.loop = false
    agent.timer = event.timer(1, function ()
        if not component.isConnected(tape) then
            _G.tape_agent[tape.address] = nil
            return false
        end
        if agent.loop and tape.isEnd() then
            tape.seek(-tape.getSize())
            tape.play()
        end
    end, math.huge)
    _G.tape_agent[tape.address] = agent
end

local rx, ry = graphic.getResolution(screen)
local window = graphic.createWindow(screen, 1, 1, rx, ry)
local layout = uix.create(window, colors.black)

local upTh, upRedraw, upCallbacks = liked.drawFullUpBarTask(screen, "Tape")

local baseTh = thread.current()
upCallbacks.exit = function ()
    baseTh:kill()
end

local tapeLabel = layout:createInput(19, 3, rx - 19, nil, nil, false, nil, nil, 32, "label: ")
function tapeLabel:onTextChanged(text)
    tape.setLabel(text)
end

layout:createText(2, 7, nil, "loop: ")
local loopMode = layout:createSwitch(8, 7, agent.loop)
function loopMode:onSwitch()
    agent.loop = self.state
end

local playButton = layout:createButton(2, 3, 16, 1, nil, nil, "PLAY")
local stopButton = layout:createButton(2, 5, 16, 1, nil, nil, "STOP")
function playButton:onClick()
    tape.play()
end

function stopButton:onClick()
    tape.stop()
end


local playLed = layout:createLabel(15, 7, 3, 1)
local seekBar = layout:createSeek(2, ry - 1, rx - 2)

function seekBar:onSeek(value)
    tape.seek((value * tape.getSize()) - tape.getPosition())
end

local writeButton = layout:createButton(19, 5, 16, 1, nil, nil, "WRITE FILE", true)
local writeUrlButton = layout:createButton(19 + 17, 5, 16, 1, nil, nil, "WRITE URL", true)
local resetSpeedButton = layout:createButton(2, 11, 16, 1, nil, nil, "RESET SPEED", true)

local function tapeCheck()
    if not tape.isReady() then
        gui.warn(screen, nil, nil, "tape is missing")
        redraw()
        return true
    end
end

local function writeFile(path)
    if tapeCheck() then return end

    if not path then
        local clear = saveBigZone(screen)
        path = gui_filepicker(screen, nil, nil, nil, "dfpwm", false, false)
        if not path then
            redraw()
            return
        end
        clear()
    end

    local label = tape.getLabel()
    if not label or label == "" then
        label = "unknown"
    end

    if gui.yesno(screen, nil, nil, "are you sure you want to write \'" .. paths.hideExtension(paths.name(path)) .. "\' to \'" .. label .. "\' tape?") then
        if gui.yesno(screen, nil, nil, "rewind the tape?") then
            tape.stop()
            tape.seek(-tape.getSize())
        else
            tape.stop()
        end

        gui.status(screen, nil, nil, "Writing The Tape...")

        local file = fs.open(path, "rb")
        while true do
            local data = file.readMax()
            if not data then
                break
            end
            tape.write(data)
        end
        file.close()
    end

    redraw()
end

function writeButton:onClick()
    writeFile()
end

local function setupConnection(url)
    local file, reason = component.internet.request(url)
    local connected

    if not file then
        gui.warn(screen, nil, nil, "error requesting data from URL: " .. reason .. "\n")
        return false
    end

    for i = 1, 10 do
        connected, reason = file.finishConnect()
        os.sleep(0.1)
        if connected or connected == nil then
            break
        end
    end
  
    if connected == nil then
        gui.warn(screen, nil, nil, "Could not connect to server: " .. reason)
        return false
    end

    local status, message, header = file.response()

    if status then
        status = string.format("%d", status)
        if status:sub(1,1) == "2" then
            return true, file
        end
        return false
    end
    gui.warn(screen, nil, nil, "no valid HTTP response - no response")
    return false
end

function writeUrlButton:onClick()
    if tapeCheck() then return end

    local internet = component.internet
    if not internet then
        gui.warn(screen, nil, nil, "an internet map component is required")
        redraw()
        return
    end

    local url = gui.input(screen, nil, nil, "dfpwm url")
    if not url then
        redraw()
        return
    end

    local label = tape.getLabel()
    if not label or label == "" then
        label = "unknown"
    end

    if gui.yesno(screen, nil, nil, "are you sure you want to write \'" .. url .. "\' to \'" .. label .. "\' tape?") then
        if gui.yesno(screen, nil, nil, "rewind the tape?") then
            tape.stop()
            tape.seek(-tape.getSize())
        else
            tape.stop()
        end

        gui.status(screen, nil, nil, "Writing The Tape...")

        local success, file = setupConnection(url)
        if not success or not file then
            gui.warn(screen, nil, nil, tostring(file or "unknown error"))
            redraw()
            return
        end

        while true do
            local data = file.read(math.huge)
            if not data then
                break
            end
            tape.write(data)
        end
        file:close()
    end

    redraw()
end

local rewindButton = layout:createButton(2, 9, 16, 1, nil, nil, "REWIND")
local wipeButton = layout:createButton(2 + 17, 9, 16, 1, nil, nil, "WIPE", true)

function rewindButton:onClick()
    tape.seek(-tape.getSize())
end

function wipeButton:onClick()
    if tapeCheck() then return end

    if gui.yesno(screen, nil, nil, "Are you sure you want to wipe this tape?") then
        gui.status(screen, nil, nil, "Cleaning The Tape...")
        local k = tape.getSize()
        tape.stop()
        tape.seek(-k)
        tape.stop() --Just making sure
        tape.seek(-90000)
        local s = string.rep("\xAA", 8192)
        for i = 1, k + 8191, 8192 do
            tape.write(s)
        end
        tape.seek(-k)
        tape.seek(-90000)
    end

    redraw()
end

layout:createText(2, ry - 5, nil, "volume: ")
layout:createText(2, ry - 3, nil, "speed : ")

local volBar = layout:createSeek(10, ry - 5, rx - 10, nil, nil, nil, agent.volume)
local speedBar = layout:createSeek(10, ry - 3, rx - 10, nil, nil, nil, agent.speed / 2)

tape.setVolume(agent.volume)
tape.setSpeed(agent.speed)

function volBar:onSeek(value)
    tape.setVolume(value)
    agent.volume = value
end

function speedBar:onSeek(value)
    tape.setSpeed(value * 2)
    agent.speed = value * 2
end

function resetSpeedButton:onClick()
    tape.setSpeed(1)
    agent.speed = 1
    speedBar.value = 0.5
    speedBar:draw()
end

------------------------------

local oldReady
local oldPlay
local oldSeek

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
    
    if not seekBar.focus then
        local val = math.round((tape.getPosition() / size) * 80) / 80
        if val < 0 or val ~= val then val = 0 end
        if val > 1 then val = 1 end
        seekBar.value = val
        if seekBar.value ~= oldSeek then
            seekBar:draw()
            oldSeek = seekBar.value
        end
    end

    local playing = state == "PLAYING"
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
end

thread.create(function ()
    while true do
        doTape()
        os.sleep(0.25)
    end
end):resume()

function redraw()
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

if path then
    writeFile(path)
end

while true do
    local eventData = {event.pull()}
    local windowEventData = window:uploadEvent(eventData)
    layout:uploadEvent(windowEventData)
end