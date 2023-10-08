local graphic = require("graphic")
local component = require("component")

local screen = ...
local gpu = graphic.findGpu(screen)
if not gpu then return end
pcall(component.invoke, screen, "turnOn")

local mx, my = graphic.maxResolution(screen)
if mx > 80 or my > 25 then
    mx = 80
    my = 25
end

local function clr()
    gpu.setBackground(0x000000)
    gpu.setForeground(0xffffff)
    gpu.fill(1, 1, mx, my, " ")
end

graphic.setResolution(screen, mx, my)

clr()

graphic.setDepth(screen, 1)
graphic.setDepth(screen, graphic.maxDepth(screen))

clr()

system_applyTheme("/data/theme.plt", screen)

clr()