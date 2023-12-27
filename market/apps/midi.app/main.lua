local uix = require("uix")
local midi = require("midi")

local screen, nickname, path = ...
local player = midi.create(path, midi.instruments())

local ui = uix.manager(screen)



ui:loop()