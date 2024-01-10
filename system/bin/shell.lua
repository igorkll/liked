local liked = require("liked")
local thread = require("thread")
local event = require("event")
local screensaver = require("screensaver")
local computer = require("computer")
local registry = require("registry")
local lastinfo = require("lastinfo")
local vkeyboard = require("vkeyboard")
local vcursor = require("vcursor")
local apps = require("apps")
local graphic = require("graphic")
local account = require("account")
local internet = require("internet")
local component = require("component")
local screen = ...

local t = thread.create(function ()
    while doSetup or account.loginWindowOpenFlag do
        os.sleep()
    end
    
    if not registry.systemConfigured then
        assert(apps.execute("setup", screen))
    end
    if component.isPrimary(screen) and internet.check() and account.getLocked() and not account.checkToken() then
        account.loginWindow(screen)
    end
    
    assert(apps.execute("login", screen))
    assert(apps.execute("desktop", screen))
end)
t:resume()

local oldScreenSaverTime = computer.uptime()
local function runScreenSaver(force)
    if force or screensaver.isEnabled(screen) then
        if not screensaver.current(screen) then
            t:suspend()
            screensaver.waitStart(screen)
            t:resume()
        end
    end

    oldScreenSaverTime = computer.uptime()
end

if graphic.getDeviceTier(screen) <= 1 then
    vcursor.hook(screen)
    vcursor.setEnable(screen, true)
end

vkeyboard.hook(screen, function ()
    oldScreenSaverTime = computer.uptime()
end)

while true do
    local eventData = {event.pull(0.1)}

    if eventData[1] == "screenSaverDemo" and eventData[2] == screen then
        runScreenSaver(true)
    elseif (eventData[1] == "touch" or eventData[1] == "scroll" or eventData[1] == "drag") and eventData[2] == screen then
        oldScreenSaverTime = computer.uptime()
    elseif (eventData[1] == "key_down" or eventData[1] == "key_up" or eventData[1] == "clipboard") and table.exists(lastinfo.keyboards[screen] or {}, eventData[2]) then
        oldScreenSaverTime = computer.uptime()
    elseif (eventData[1] == "vcursor_key_down" or eventData[1] == "vcursor_key_up" or eventData[1] == "vcursor_clipboard") and table.exists(lastinfo.keyboards[screen] or {}, eventData[2]) then
        oldScreenSaverTime = computer.uptime()
    elseif registry.screenSaverTimer and computer.uptime() - oldScreenSaverTime > registry.screenSaverTimer then
        runScreenSaver()
    end
end