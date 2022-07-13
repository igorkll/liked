local fs = require("filesystem")
local calls = require("calls")
local path = ...

pcall(fs.copy, path, "/data/theme.plt")
if not pcall(calls.call, "system_applyTheme", path) then
    calls.call("system_setTheme", "/system/themes/classic.plt")
end