local uix = require("uix")
local unicode = require("unicode")
local fs = require("filesystem")
local system = require("system")
local paths = require("paths")

local screen = ...
local ui = uix.manager(screen)
local layout = ui:create("Gui Demo")

for i, path in ipairs(fs.list(system.getResourcePath("demo"), true)) do
    local title = paths.hideExtension(paths.name(path))
    local button = layout:createButton(2, 2 + ((i - 1) * 2), 24, 1, nil, nil, title, true)
    local localLayout = ui:create(title)
    dofile(path, screen, localLayout, uix.colors, ui:zoneSize())
    localLayout:setReturnLayout(layout)

    function button:onClick()
        ui:select(localLayout)
    end
end

ui:loop()