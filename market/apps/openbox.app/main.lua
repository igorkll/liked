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

openbox.run(screen, program)