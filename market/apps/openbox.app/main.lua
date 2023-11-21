local iowindows = require("iowindows")
local openbox = require("openbox")
local fs = require("filesystem")

--------------------------------

local screen = ...
local program = iowindows.loadfile(screen)
if not program then
    return
end

local box = openbox.create(screen)
assert(box:execute(assert(fs.readFile(program))))