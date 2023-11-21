local thread = require("thread")
local event = require("event")
local graphic = require("graphic")
local programs = require("programs")
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
    local th = thread.createBackground(programs.load(path or require("gui_container").screenSaverPath), screen)
    th.parentData.screen = screen
    th:resume()
    event.yield()
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

function screensaver.waitStart(screen, path)
    screensaver.start(screen, path)
    while screensaver.current(screen) do
        event.sleep()
    end
end


screensaver.unloadable = true
return screensaver