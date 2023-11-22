local uix = require("uix")
local gui = require("gui")

local screen = ...
local navigation = gui.selectcomponentProxy(screen, nil, nil, "navigation", true)
local manager = uix.manager(screen)
local layout = manager:create("Navigation", uix.colors.white)

local canvas = layout:createCanvas(15, 1, 48, 24, uix.colors.white)


manager:loop()