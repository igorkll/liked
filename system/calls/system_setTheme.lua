local fs = require("filesystem")
local path = ...

if pcall(system_applyTheme, path) then
    pcall(fs.copy, path, "/data/theme.plt")
else
    pcall(fs.copy, "/system/themes/classic.plt", "/data/theme.plt")
    system_applyTheme("/system/themes/classic.plt")
end