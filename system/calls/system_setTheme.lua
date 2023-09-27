local fs = require("filesystem")
local calls = require("calls")
local path = ...

if pcall(calls.call, "system_applyTheme", path) then
    pcall(fs.copy, path, "/data/theme.plt")
else
    pcall(fs.copy, "/system/themes/classic.plt", "/data/theme.plt")
    system_applyTheme("/system/themes/classic.plt")
end