local screen = ...
local graphic = require("graphic")
local gpu = graphic.findGpu(screen)
if not gpu then return end


local mx, my = graphic.maxResolution(screen)
if mx > 80 or my > 25 then
    mx = 80
    my = 25
end
graphic.setResolution(screen, mx, my)

--ядро likeOS само сбрасывает палитру и устанавливает максимальную глубину цвета
--graphic.setDepth(screen, graphic.maxDepth(screen))


gpu.setBackground(0x000000)
gpu.setForeground(0xffffff)
gpu.fill(1, 1, mx, my, " ")


system_setTheme("/data/theme.plt")