local liked = require("liked")
local thread = require("thread")
local event = require("event")
local screensaver = require("screensaver")
local computer = require("computer")
local registry = require("registry")
local lastinfo = require("lastinfo")
local vkeyboard = require("vkeyboard")
local screen = ...

vkeyboard.hook(screen)

local t = thread.create(function ()
    assert(liked.execute("login", screen))
    assert(liked.execute("desktop", screen))
end)
t:resume()

local oldScreenSaverTime = computer.uptime()

local function runScreenSaver(force)
    if force or screensaver.isEnabled(screen) then
        if not screensaver.current(screen) then
            t:suspend()
            screensaver.waitStart(screen)
            oldScreenSaverTime = computer.uptime()
            t:resume()
        else
            oldScreenSaverTime = computer.uptime()
        end
    end
end

while true do
    local eventData = {event.pull(0.1)}

    if eventData[1] == "screenSaverDemo" and eventData[2] == screen then
        runScreenSaver(true)
    end

    if (eventData[1] == "touch" or eventData[1] == "scroll" or eventData[1] == "drag") and eventData[2] == screen then
        oldScreenSaverTime = computer.uptime()
    elseif (eventData[1] == "key_down" or eventData[1] == "key_up" or eventData[1] == "clipboard" or eventData[1] == "softwareInsert") and table.exists(lastinfo.keyboards[screen], eventData[2]) then
        oldScreenSaverTime = computer.uptime()
    end

    if registry.screenSaverTimer and computer.uptime() - oldScreenSaverTime > registry.screenSaverTimer then
        runScreenSaver()
    end
end