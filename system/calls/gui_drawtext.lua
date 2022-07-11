local graphic = require("graphic")
local unicode = require("unicode")

------------------------------------

local screen, posX, posY, foreground, text = ...
local gpu = graphic.findGpu(screen)

------------------------------------

gpu.setForeground(foreground)
for i = 1, unicode.len(text) do
    local char, fore, back = gpu.get(posX + (i - 1), posY)
    gpu.setBackground(back)
    gpu.set(posX + (i - 1), posY, unicode.sub(text, i, i))
end