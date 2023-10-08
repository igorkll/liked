local graphic = require("graphic")
local gui = require("gui")
local component = require("component")
local liked = require("liked")
local thread = require("thread")
local event = require("event")

local screen = ...
local cb = gui.selectcomponent(screen, nil, nil, {"command_block"}, true)
if not cb then
    return
else
    cb = component.proxy(cb)
end
liked.drawFullUpBarTask(screen, "CommandBlock")
local rx, ry = graphic.getResolution(screen)
local term = require("term").create(screen, 1, 2, rx, ry - 1, true)
term:clear()

local baseTh = thread.current()
thread.create(function ()
    while true do
        local eventData = {event.pull()}
        if eventData[1] == "touch" and eventData[2] == screen then
            if eventData[3] == rx and eventData[4] == 1 then
                baseTh:kill()
            end
        end
    end
end):resume()

while true do
    term:write("> ")
    local command = term:readLn()
    if not command then break end
    cb.setCommand(command)
    local _, ret = cb.executeCommand()
    if ret then
        term:write(ret)
    end
    term:newLine()
end