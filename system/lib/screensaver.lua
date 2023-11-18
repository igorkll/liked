local thread = require("thread")
local screensaver = {}

local enabled = {}
local current = {}


function screensaver.isEnabled(screen)
    return enabled[screen] == true or enabled[screen] == nil
end

function screensaver.setEnabled(screen, state)
    enabled[screen] = not not state
end


function screensaver.current(screen)
    return current[screen]
end

function screensaver.start(screen, path)
    current[screen] = thread.createBackground(function ()
        
    end)
end


screensaver.unloadable = true
return screensaver