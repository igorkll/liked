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
local cb = gui.selectcomponentProxy(screen, nil, nil, {"command_block", "debug"}, true)
if not cb then
    return
end

local _, drawUp, callbacks = liked.drawFullUpBarTask(screen, "CommandBlock")
local rx, ry = graphic.getResolution(screen)
local term = require("term").create(screen, 1, 2, rx, ry - 1, true)
term:clear()
drawUp()

local baseTh = thread.current()
function callbacks.exit()
    baseTh:kill()
end

local queue
if path then
    queue = {}
    local content = assert(fs.readFile(path))
    for _, command in ipairs(parser.split(unicode, content, "\n")) do
        table.insert(queue, command)
    end
end

while true do
    term:write("> ")
    local command
    if queue and #queue > 0 then
        command = table.remove(queue, 1)
        term:writeLn(command)
    else
        command = term:readLn()
        if not command then
            break
        end
    end

    if cb.type == "debug" then
        local ret = tostring(cb.runCommand(command))
        if ret then
            term:write(ret)
        end
    else
        cb.setCommand(command)
        local _, ret = cb.executeCommand()
        if ret then
            term:write(ret)
        end
    end
    term:newLine()
    graphic.forceUpdate(screen)

    if queue and #queue == 0 then
        os.sleep(1)
        break
    end
end