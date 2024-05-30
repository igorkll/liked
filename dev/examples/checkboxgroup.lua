local uix = require("uix")
local gobjs = require("gobjs")
local ui = uix.manager(...)
local rx, ry = ui:zoneSize()
local layout = ui:create("ui test", uix.colors.black)

layout:createCustom(2, 2, gobjs.checkboxgroup, rx - 2, ry - 2)

ui:loop()