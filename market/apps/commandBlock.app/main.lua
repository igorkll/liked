local graphic = require("graphic")
local gui = require("gui")
local component = require("component")
local liked = require("liked")
local thread = require("thread")
local event = require("event")
local fs = require("filesystem")
local parser = require("parser")
local unicode = require("unicode")

local screen, nickname, path = ...
local cb = gui.selectcomponent(screen, nil, nil, {"command_block"}, true)
if not cb then
    return
else
    cb = component.proxy(cb)
end

local _, drawUp = liked.drawFullUpBarTask(screen, "CommandBlock")
local rx, ry = graphic.getResolution(screen)
local term = require("term").create(screen, 1, 2, rx, ry - 1, true)
term:clear()
drawUp()

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

local queue = {}
if path then
    local content = assert(fs.readFile(path))
    for _, command in ipairs(parser.split(unicode, content, "\n")) do
        table.insert(queue, command)
    end
end

while true do
    term:write("> ")
    local command
    if #queue > 0 then
        command = table.remove(queue, 1)
        term:writeLn(command)
    else
        command = term:readLn()
    end
    if not command then break end
    cb.setCommand(command)
    local _, ret = cb.executeCommand()
    if ret then
        term:write(ret)
    end
    term:newLine()
    graphic.forceUpdate()
end