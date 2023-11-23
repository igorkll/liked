local iowindows = require("iowindows")
local openbox = require("openbox")
local system = require("system")

--------------------------------

local screen = ...
openbox.run(screen, system.getResourcePath("program.lua"))