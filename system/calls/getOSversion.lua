local fs = require("filesystem")

local file = fs.open("/system/version.cfg", "rb")
local data = tonumber(file.readAll())
file.close()

return data