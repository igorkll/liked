local fs = require("filesystem")
local calls = require("calls")

--------------------------------------------

local gui_container = {}

gui_container.colors = {}
gui_container.indexsColors = {}
gui_container.filesExps = {}
gui_container.devModeStates = {}
gui_container.typecolors = {
    app = gui_container.colors.red,
    lua = gui_container.colors.lime
}
gui_container.typenames = {
    t2p = "image",
}

_G.gui_container = gui_container
if fs.exists("/data/theme.plt") then
    calls.call("system_applyTheme", "/data/theme.plt")
else
    calls.call("system_setTheme", "/system/themes/classic.plt")
end
_G.gui_container = nil

return gui_container