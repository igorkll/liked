local uix = require("uix")

local screen = ...
local ui = uix.manager(screen)
local layout = ui:create("Clock", )


ui:loop()