local graphic = require("graphic")
local calls = require("calls")
local explorer = require("explorer")

local gpu = ...
calls.call("graphicInit", gpu)

local count = 0
for i, v in pairs(explorer.colors) do
    gpu.setPaletteColor(count, v)
    count = count + 1
end