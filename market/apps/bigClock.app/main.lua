local time = require("time")
local graphic = require("graphic")
local colors = require("gui_container").colors
local thread = require("thread")
local registry = require("registry")
local computer = require("computer")
local screen = ...

local rx, ry = graphic.getResolution(screen)

local exit
thread.listen("close", function(_, uuid)
    if screen == uuid then
        exit = true
    end
end)

while true do
    local rtc = time.formatTime(time.addTimeZone(time.getRealTime(), registry.timeZone or 0), true)
    local gtc = time.formatTime(time.getGameTime(), true)

    graphic.clear(screen, colors.black)
    graphic.set(screen, 1, 1, colors.black, colors.pink, rtc)
    graphic.set(screen, 1, 2, colors.black, colors.cyan, gtc)
    graphic.update(screen)

    os.sleep(0.1)

    if exit then
        break
    end
end