local uix = require("uix")
local ui = uix.manager(...)

local layout1 = ui:create()
local layout2 = ui:create("LOLZ")

function ui:onExit()
    require("computer").beep()
end

ui:loop()