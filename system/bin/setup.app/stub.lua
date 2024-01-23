local uix = require("uix")

local screen = ...
local ui = uix.manager(screen)
local rx, ry = ui:size()

local layout = ui:simpleCreate(uix.colors.cyan, uix.styles[2])
layout:createText(2, 2, uix.colors.white, "configuration expectations...")

ui:loop()