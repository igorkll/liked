local fs = require("filesystem")
local path = ...

if pcall(system_applyTheme, path) then
    pcall(fs.copy, path, _G.initPalPath)
else
    pcall(fs.copy, "/system/themes/classic.plt", _G.initPalPath)
    system_applyTheme("/system/themes/classic.plt")
end