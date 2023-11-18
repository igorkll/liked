local thread = require("thread")
local event = require("event")
local graphic = require("graphic")
local liked = require("liked")
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
    local clear = graphic.screenshot(screen)
    
    local th = thread.createBackground(liked.loadApp, path, screen)

    event.listen(nil, function (eventName, uuid)
        if uuid == screen and (eventName == "touch" or eventName == "drag" or eventName == "scroll") then
            current[screen] = nil
            th:kill()
            clear()
            return false
        end
    end)

    current[screen] = th
end


screensaver.unloadable = true
return screensaver