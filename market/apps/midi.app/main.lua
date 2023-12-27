local gui = require("gui")
local uix = require("uix")
local midi = require("midi")

local screen, nickname, path = ...
local player = path and midi.create(path, midi.instruments())

local ui = uix.manager(screen)
local rx, ry = ui:zoneSize()
local layout = ui:create("Midi Player")
local playButton = layout:createButton(2, 2, 16, 1, nil, nil, "Play", true)
local pauseButton = layout:createButton(2, 4, 16, 1, nil, nil, "Pause", true)
local stopButton = layout:createButton(2, 6, 16, 1, nil, nil, "Stop", true)

local midfile = layout:createLabel(19, 2, 32, 1)
local midth = layout:createLabel(19, 4, 32, 1)
local function updateLabels()
    if _G.playerObj then
        midfile.text = gui.hideExtension(screen, _G.playerObj.filepath)
    else
        midfile.text = nil
    end

    if _G.playerThread then
        local state = _G.playerThread:status()
        if state == "running" then
            midth.text = "playing"
        elseif state == "suspended" then
            midth.text = "paused"
        else
            midth.text = state
        end
    else
        midth.text = "stopped"
    end

    midfile:draw()
    midth:draw()
end
updateLabels()

local resetSettings = layout:createButton(2, ry - 7, 16, 1, nil, nil, "reset", true)
layout:createText(2, ry - 5, nil, "speed   :")
layout:createText(2, ry - 3, nil, "pitch   :")
layout:createText(2, ry - 1, nil, "note len:")
local speedSeek   = layout:createSeek(12, ry - 5, rx - 12)
local pitchSeek   = layout:createSeek(12, ry - 3, rx - 12)
local noteLenSeek = layout:createSeek(12, ry - 1, rx - 12)
local function readSliders()
    if _G.playerObj then
        speedSeek.value = _G.playerObj.speed / 2
        pitchSeek.value = _G.playerObj.pitch / 2
        noteLenSeek.value = _G.playerObj.noteduraction / 2
    else
        speedSeek.value = 0.5
        pitchSeek.value = 0.5
        noteLenSeek.value = 0.5
    end
end
local function writeSliders()
    if _G.playerObj then
        _G.playerObj.speed = speedSeek.value * 2
        _G.playerObj.pitch = pitchSeek.value * 2
        _G.playerObj.noteduraction = noteLenSeek.value * 2
    end
end
readSliders()

function resetSettings:onClick()
    speedSeek.value = 0.5
    pitchSeek.value = 0.5
    noteLenSeek.value = 0.5

    if _G.playerObj then
        _G.playerObj.speed = speedSeek.value * 2
        _G.playerObj.pitch = pitchSeek.value * 2
        _G.playerObj.noteduraction = noteLenSeek.value * 2
    end
    
    speedSeek:draw()
    pitchSeek:draw()
    noteLenSeek:draw()
end

function speedSeek:onSeek()
    writeSliders()
end

function pitchSeek:onSeek()
    writeSliders()
end

function noteLenSeek:onSeek()
    writeSliders()
end

function playButton:onClick()
    if not _G.playerThread then
        if player then
            _G.playerThread = player.createBackgroundThread(true)
            _G.playerObj = player
        else
            gui.warn(screen, nil, nil, "open the midi file to start playback")
            ui:draw()
        end
    end

    if _G.playerThread then
        _G.playerThread:resume()
    end

    updateLabels()
    writeSliders()
end

function pauseButton:onClick()
    if _G.playerThread then
        _G.playerThread:suspend()
    end

    updateLabels()
end

function stopButton:onClick()
    if _G.playerThread then
        _G.playerThread:kill()
        _G.playerThread = nil
    end

    _G.playerObj = nil
    updateLabels()
end

ui:loop()