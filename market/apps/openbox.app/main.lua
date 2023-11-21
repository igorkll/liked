local iowindows = require("iowindows")
local openbox = require("openbox")
local fs = require("filesystem")
local gui = require("gui")
local event = require("event")
local lastinfo = require("lastinfo")

--------------------------------

local screen = ...
local program = iowindows.loadfile(screen)
if not program then
    return
end

local box = openbox.create(screen)
local ok, err = box:execute(assert(fs.readFile(program)))
if not ok then
    gui.bigWarn(screen, nil, nil, tostring(err))
end
box.term:print("press enter key to exit the emulator...")
event.pull("key_down", lastinfo.keyboards[screen][1], 13, 28)
box:clear()