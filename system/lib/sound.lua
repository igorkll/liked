local computer = require("computer")
local component = require("component")
local sound = {}

function sound.warn()
    computer.beep(100)
    computer.beep(100)
end

sound.unloadable = true
return sound