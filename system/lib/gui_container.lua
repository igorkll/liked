local fs = require("filesystem")
local calls = require("calls")

--------------------------------------------

local gui_container = {}

gui_container.colors = {}
gui_container.indexsColors = {}

local function attempt(path)
    if fs.exists(path) then
        calls.call("system_applyTheme", path)
        return false
    end
    return true
end

_G.gui_container = gui_container
if fs.exists("/data/theme.plt") then
    calls.call("system_applyTheme", "/data/theme.plt")
else
    pcall(fs.copy, "/system/themes/classic.plt", "/data/theme.plt")
    calls.call("system_applyTheme", "/system/themes/classic.plt")
end
_G.gui_container = nil

return gui_container