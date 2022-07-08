local fs = require("filesystem")
local path = ...

------------------------------------

local file = fs.open(path, "rb")
local sx = string.byte(file.read(1))
local sy = string.byte(file.read(1))
file.close()

------------------------------------

return sx, sy