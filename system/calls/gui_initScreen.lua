local graphic = require("graphic")
local calls = require("calls")
local gui_container = require("gui_container")

local screen = ...
local gpu = graphic.findGpu(screen)

calls.call("graphicInit", gpu)
gpu.setDepth(4)
--gpu.setResolution(80, 25)

local count = 0
for i, v in pairs(gui_container.colors) do
    gpu.setPaletteColor(count, v)
    count = count + 1
end