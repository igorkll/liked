local graphic = require("graphic")
local calls = require("calls")
local gui_container = require("gui_container")

local screen = ...
local gpu = graphic.findGpu(screen)

calls.call("graphicInit", gpu)
gpu.setDepth(4)
--gpu.setResolution(80, 25)

system_setTheme("/data/theme.plt")