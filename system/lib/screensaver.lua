local fs = require("filesystem")
local thread = require("thread")
local event = require("event")
local graphic = require("graphic")
local programs = require("programs")
local logs = require("logs")
local cache = require("cache")
local screensaver = {}

cache.static.screensaver_enabled = cache.static.screensaver_enabled or {}
cache.static.screensaver_current = cache.static.screensaver_current or {}

function screensaver.isEnabled(screen)
    return cache.static.screensaver_enabled[screen] == true or cache.static.screensaver_enabled[screen] == nil
end

function screensaver.setEnabled(screen, state)
    cache.static.screensaver_enabled[screen] = not not state
end


function screensaver.current(screen)
    return cache.static.screensaver_current[screen]
end

function screensaver.start(screen, path)
    local lpath = path or require("gui_container").screenSaverPath
    if lpath and fs.exists(lpath) then
        local clear = graphic.screenshot(screen)
        local th = thread.createBackground(logs.check(programs.load(lpath)) or function() end, screen)
        th.parentData.screen = screen
        th:resume()
        event.yield()
        event.listen(nil, function (eventName, uuid)
            if uuid == screen and (eventName == "touch" or eventName == "drag" or eventName == "scroll") then
                cache.static.screensaver_current[screen] = nil
                th:kill()
                clear()
                return false
            end
        end)
        cache.static.screensaver_current[screen] = th
    end
end

function screensaver.waitStart(screen, path)
    screensaver.start(screen, path)
    while screensaver.current(screen) do
        event.sleep()
    end
end

screensaver.unloadable = true
return screensaver