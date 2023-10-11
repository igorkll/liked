--t2p drawer
--t2p(tier 2 pic), bytes <sizeX> <sizeY> <зарезервировано> <зарезервировано> <зарезервировано> <зарезервировано> <зарезервировано> <зарезервировано> <зарезервировано> <зарезервировано> <4bit background, 4 bit foreground> <count char bytes> <char byte> 
local fs = require("filesystem")
local graphic = require("graphic")
local calls = require("calls")
local gui_container = require("gui_container")
local cache = require("cache")
local paths = require("paths")
local unicode = require("unicode")

local screen, path, x, y = ...
local gpu = graphic.findGpu(screen)

local readbit = calls.load("readbit")
local colors = gui_container.indexsColors

path = paths.canonical(path)

------------------------------------

cache.cache.images = cache.cache.images or {}

local buffer
local lcache = cache.cache.images[path]
if lcache and fs.lastModified(path) == lcache[2] then
    buffer = lcache[1]
else
    buffer = assert(fs.readFile(path))
    cache.cache.images[path] = {buffer, fs.lastModified(path)}
end

local function read(bytecount)
    local str = buffer:sub(1, bytecount)
    buffer = buffer:sub(bytecount + 1, #buffer)
    return str
end

------------------------------------

local sx = string.byte(read(1))
local sy = string.byte(read(1))
read(8)

local function norm(x, y, text)
    if x <= 0 then
        return 1, y, unicode.sub(text, 2 - x, unicode.len(text))
    end
    return x, y, text
end

local colorByte, countCharBytes
local oldX, oldY = 1, 1
local oldFore, oldBack
local buff = ""
for cy = 1, sy do
    for cx = 1, sx do
        colorByte      = string.byte(read(1))
        countCharBytes = string.byte(read(1))

        local background = 
        ((readbit(colorByte, 0) and 1 or 0) * 1) + 
        ((readbit(colorByte, 1) and 1 or 0) * 2) + 
        ((readbit(colorByte, 2) and 1 or 0) * 4) + 
        ((readbit(colorByte, 3) and 1 or 0) * 8)
        local foreground = 
        ((readbit(colorByte, 4) and 1 or 0) * 1) + 
        ((readbit(colorByte, 5) and 1 or 0) * 2) + 
        ((readbit(colorByte, 6) and 1 or 0) * 4) + 
        ((readbit(colorByte, 7) and 1 or 0) * 8)
        if not oldFore then oldFore = foreground end
        if not oldBack then oldBack = background end

        local char = read(countCharBytes)

        if foreground ~= oldFore or background ~= oldBack or oldY ~= cy then
            if oldBack ~= 0 or oldFore ~= 0 then --прозрачность, в реальной картинке такого не будет потому что если paint замечает оба нуля то он меняет одной значения чтобы пиксель не мог просто так стать прозрачным
                if oldBack == oldFore then
                    gpu.setBackground(colors[oldBack + 1])
                    gpu.set(norm(oldX + (x - 1), oldY + (y - 1), string.rep(" ", unicode.len(buff))))
                else
                    gpu.setBackground(colors[oldBack + 1])
                    gpu.setForeground(colors[oldFore + 1])
                    gpu.set(norm(oldX + (x - 1), oldY + (y - 1), buff))
                end
            end

            oldFore = foreground
            oldBack = background
            oldX = cx
            oldY = cy
            buff = char
        else
            buff = buff .. char
        end
    end
end

if oldBack ~= 0 or oldFore ~= 0 then
    if oldBack == oldFore then
        gpu.setBackground(colors[oldBack + 1])
        gpu.set(norm(oldX + (x - 1), oldY + (y - 1), string.rep(" ", unicode.len(buff))))
    else
        gpu.setBackground(colors[oldBack + 1])
        gpu.setForeground(colors[oldFore + 1])
        gpu.set(norm(oldX + (x - 1), oldY + (y - 1), buff))
    end
end