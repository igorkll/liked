local fs = require("filesystem")
local calls = require("calls")
local path = ...

fs.copy(path, "/data/theme.plt")
calls.call("system_applyTheme", path)