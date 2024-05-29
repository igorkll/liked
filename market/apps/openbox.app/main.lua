local iowindows = require("iowindows")
local openbox = require("openbox")

--------------------------------

local screen = ...
local program = iowindows.selectfile(screen, "lua")
if not program then
    return
end

openbox.runWithSplash(screen, program)