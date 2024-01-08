local computer = require("computer")
local component = require("component")
local sound = {}

function sound.warn()
    computer.beep(100)
    computer.beep(100)
end

function sound.done()
    computer.beep(1800, 0.05)
    computer.beep(1800, 0.05)
end

sound.unloadable = true
return sound