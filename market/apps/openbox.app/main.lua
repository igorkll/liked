local iowindows = require("iowindows")
local openbox = require("openbox")

--------------------------------

local screen = ...
local program = iowindows.selectfile(screen)
if not program then
    return
end

openbox.run(screen, program)