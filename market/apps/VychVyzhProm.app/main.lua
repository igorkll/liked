local openbox = require("openbox")
local system = require("system")

--------------------------------

local screen = ...
openbox.runWithSplash(screen, system.getResourcePath("vvprom/vvprom.lua"))