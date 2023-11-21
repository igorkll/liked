local iowindows = require("iowindows")
local openbox = require("openbox")
local fs = require("filesystem")
local gui = require("gui")
local event = require("event")
local lastinfo = require("lastinfo")
local graphic = require("graphic")

--------------------------------

local screen = ...
local program = iowindows.loadfile(screen)
if not program then
    return
end

local box = openbox.create(screen)
if box.term then
    box.term:clear()
end

local ok, err = box:execute(assert(fs.readFile(program)))

if box.screen then
    local gpu = graphic.findGpu(box.screen)
    gpu.setResolution(box.oldRX, box.oldRY)
end

if not ok then
    local clear = saveBigZone(screen)
    gui.bigWarn(screen, nil, nil, tostring(err))
    clear()
end

if ok then
    box.term:print("press enter key to exit the emulator...")
    event.pull("key_down", lastinfo.keyboards[screen][1], 13, 28)
end

box:clear()