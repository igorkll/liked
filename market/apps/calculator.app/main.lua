local uix = require("uix")
local ui = uix.manager(...)

local backgroundColor = uix.colors.white
local numTextColor = uix.colors.black
local buttonBackgroundColor = uix.colors.lightGray
local buttonTextColor = uix.colors.white


local layout = ui:create("Calculator", backgroundColor)


ui:loop()