--t2p drawer
--t2p(tier 2 pic), bytes <sizeX> <sizeY> <зарезервировано> <зарезервировано> <зарезервировано> <зарезервировано> <зарезервировано> <зарезервировано> <зарезервировано> <зарезервировано> <4bit background, 4 bit foreground> <count char bytes> <char byte> 
local fs = require("filesystem")
local graphic = require("graphic")
local calls = require("calls")
local gui_container = require("gui_container")

local screen, path, x, y = ...
local gpu = graphic.findGpu(screen)

local readbit = calls.load("readbit")
local colors = gui_container.indexsColors

------------------------------------

local file = fs.open(path, "rb")
local sx = string.char(file.read(1))
local sy = string.char(file.read(1))
file.seek("cur", 8)

for cy = 1, sy do
    for cx = 1, sx do
        local colorByte      = string.byte(file.read(1))
        local countCharBytes = string.byte(file.read(1))

        local background = 
        ((readbit(colorByte, 1) and 1 or 0) * 1) + 
        ((readbit(colorByte, 2) and 1 or 0) * 2) + 
        ((readbit(colorByte, 3) and 1 or 0) * 4) + 
        ((readbit(colorByte, 4) and 1 or 0) * 8)
        local foreground = 
        ((readbit(colorByte, 5) and 1 or 0) * 1) + 
        ((readbit(colorByte, 6) and 1 or 0) * 2) + 
        ((readbit(colorByte, 7) and 1 or 0) * 4) + 
        ((readbit(colorByte, 8) and 1 or 0) * 8)
        background = colors[background]
        foreground = colors[foreground]

        local char = file.read(countCharBytes)
        gpu.setBackground(background)
        gpu.setForeground(foreground)
        gpu.set(cx, cy, char)
    end
end