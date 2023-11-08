local graphic = require("graphic")
local uix = require("uix")

local screen = ...
local guimanager = {}
local layout = uix.createAuto(screen, "Card Writer")
local layout2 = uix.createAuto(screen, "LOLZ")

do
    local button = layout:createButton(2, 3, 16, 1, nil, nil, "layout 2")
    function button:onClick()
        guimanager.select(layout2)
    end
end

do
    local button = layout2:createButton(2, 3, 16, 1, nil, nil, "layout 1")
    function button:onClick()
        guimanager.select(layout)
    end
end

uix.loop(guimanager, layout)