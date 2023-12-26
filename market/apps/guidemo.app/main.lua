local uix = require("uix")
local unicode = require("unicode")
local fs = require("filesystem")
local system = require("system")
local paths = require("paths")

local screen = ...
local ui = uix.manager(screen)
local layout = ui:create("Gui Demo")

for i, path in ipairs(fs.list(system.getResourcePath("demo"), true)) do
    local button = layout:createButton(2, 2 + ((i - 1) * 2), 24, 1, nil, nil, paths.hideExtension(paths.name(path)), true)

    function button:()
        
    end
end

ui:loop()