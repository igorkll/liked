local fs = require("filesystem")
local calls = require("calls")
local path = ...

if path ~= "/data/theme.plt" then
    fs.copy(path, "/data/theme.plt")
end
calls.call("system_applyTheme", path)