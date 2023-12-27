local uix = require("uix")
local midi = require("midi")

local screen, nickname, path = ...
local player = midi.create(path, midi.instruments())

local ui = uix.manager(screen)
local layout = ui:create("Midi Player")
local playButton = layout:createButton(2, 2, 16, 1, nil, nil, "Play")
local pauseButton = layout:createButton(2, 4, 16, 1, nil, nil, "Pause")
local stopButton = layout:createButton(2, 6, 16, 1, nil, nil, "Stop")

local playerThread

function playButton:onClick()
    if not playerThread then
        playerThread = player.createThread(true)
    end

    playerThread:resume()
end

function pauseButton:onClick()
    if playerThread then
        playerThread:suspend()
    end
end

function stopButton:onClick()
    if playerThread then
        playerThread:kill()
        playerThread = nil
    end
end

ui:loop()