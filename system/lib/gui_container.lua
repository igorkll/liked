local fs = require("filesystem")
local calls = require("calls")

--------------------------------------------

local gui_container = {}

gui_container.colors = {}
gui_container.indexsColors = {}
gui_container.filesExps = {}
gui_container.devModeStates = {}

_G.gui_container = gui_container
if fs.exists("/data/theme.plt") then
    calls.call("system_applyTheme", "/data/theme.plt")
else
    calls.call("system_setTheme", "/system/themes/classic.plt")
end
_G.gui_container = nil

return gui_container