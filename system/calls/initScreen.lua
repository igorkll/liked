local graphic = require("graphic")
local calls = require("calls")
local explorer = require("explorer")

local screen = ...
local gpu = graphic.findGpu(screen)

calls.call("graphicInit", gpu)
gpu.setDepth(4)
gpu.setResolution(80, 25)

local count = 0
for i, v in pairs(explorer.colors) do
    gpu.setPaletteColor(count, v)
    count = count + 1
end