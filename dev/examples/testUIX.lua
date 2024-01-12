local uix = require("uix")
local ui = uix.manager((...))

local layout1 = ui:create()
local layout2 = ui:create("LOLZ")

local toLayout2 = layout1:createButton(2, 2, 16, 3)
function toLayout2:onClick()
    ui:select(layout2)
end

layout2:setReturnLayout(layout1)
local toLayout1 = layout2:createButton(2, 2, 16, 3)
function toLayout1:onClick()
    ui:select(layout1)
end

function ui:onExit()
    require("computer").beep()
end
ui:loop()