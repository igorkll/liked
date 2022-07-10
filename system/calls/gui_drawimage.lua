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
local buffer = file.readAll()
file.close()
local function read(bytecount)
    local str = buffer:sub(1, bytecount)
    buffer = buffer:sub(bytecount + 1, #buffer)
    return str
end

------------------------------------

local sx = string.byte(read(1))
local sy = string.byte(read(1))
read(8)

local oldbackground = gpu.getBackground()
local oldforeground = gpu.getBackground()

local colorByte, countCharBytes, background, foreground, char
for cy = 1, sy do
    for cx = 1, sx do
        colorByte      = string.byte(read(1))
        countCharBytes = string.byte(read(1))

        background = 
        ((readbit(colorByte, 1) and 1 or 0) * 1) + 
        ((readbit(colorByte, 2) and 1 or 0) * 2) + 
        ((readbit(colorByte, 3) and 1 or 0) * 4) + 
        ((readbit(colorByte, 4) and 1 or 0) * 8)
        foreground = 
        ((readbit(colorByte, 5) and 1 or 0) * 1) + 
        ((readbit(colorByte, 6) and 1 or 0) * 2) + 
        ((readbit(colorByte, 7) and 1 or 0) * 4) + 
        ((readbit(colorByte, 8) and 1 or 0) * 8)
        background = colors[background]
        foreground = colors[foreground]

        if background == 0 and foreground == 0 then
            char = read(countCharBytes)
            if background ~= oldbackground then
                gpu.setBackground(background)
                oldbackground = background
            end
            if foreground ~= oldforeground then
                gpu.setForeground(foreground)
                oldforeground = foreground
            end
            gpu.set(cx + (x - 1), cy + (y - 1), char)
        end
    end
end