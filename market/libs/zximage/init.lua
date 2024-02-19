local serialization = require("serialization")
local system = require("system")
local fs = require("filesystem")
local graphic = require("graphic")
local unicode = require("unicode")
local zximage = {}
zximage.sizeX = 128
zximage.sizeY = 48
zximage.palettePath = system.getResourcePath("palette.plt")

local byte = string.byte

function zximage.pallete()
    return serialization.load(zximage.palettePath)
end

function zximage.check(path)
    if fs.size(path) ~= 6912 then
        return nil, "this file is not a picture from the ZX spectrum"
    end

    return true
end

function zximage.parse(path, callback)
    local ok, err = zximage.check(path)
    if not ok then
        return nil, err
    end

    local function lolzAlloc(count, tbl)
        tbl = tbl or {}
        for i = 0, count - 1 do
            tbl[i] = 0
        end
        return tbl
    end
    
    local reader = fs.open(path, "rb", true)
    local rawPixels = {}
    for y = 0, 191 do
        rawPixels[y] = {reader.read(32):byte(1, -1)}
    end
    local attributes = reader.read(768)
    reader.close()    
    
    local function braille(b)
        return 0x2800 + ((b & 1) << 7) + ((b & 2) << 5) + ((b & 4) << 3) + ((b & 8) >> 1) + ((b & 16)) + ((b & 32) >> 4) + ((b & 64) >> 3) + ((b & 128) >> 7);
    end
    
    local function addr(y)
        return (y & 192) + ((y & 56) >> 3) + ((y & 7) << 3)
    end
    
    local backColors = lolzAlloc(768)
    local foreColors = lolzAlloc(768)
    
    for i = 0, 767 do
        backColors[i] = (attributes:byte(i + 1) & 56) >> 3
        if (attributes:byte(i + 1) & 64) == 64 and backColors[i] ~= 0 then
            backColors[i] = backColors[i] + 8
        end
    
        foreColors[i] = attributes:byte(i + 1) & 7
        if (attributes:byte(i + 1) & 64) == 64 and foreColors[i] ~= 0 then
            foreColors[i] = foreColors[i] + 8
        end
    end
    
    local index, b, buffer
    for l = 0, 47 do
        buffer = lolzAlloc(128, buffer)
        for y = 0, 3 do
            for x = 0, 31 do
                b = rawPixels[addr(y + l * 4)][x + 1]
                for i = 3, 0, -1 do
                    buffer[i + x * 4] = buffer[i + x * 4] + (b & 3)
                    b = b >> 2
                    if y < 3 then
                        buffer[i + x * 4] = buffer[i + x * 4] << 2
                    end
                end
            end
        end
    
        for i = 0, 127 do
            index = i // 4 + l // 2 * 32
            callback(i + 1, l + 1, backColors[index], foreColors[index], unicode.char(braille(buffer[i])))
        end
    end

    return true
end

function zximage.applyPalette(screen)
    graphic.setPalette(screen, zximage.pallete(), true)
end

function zximage.applyResolution(screen, crop)
    if crop then
        graphic.setResolution(screen, zximage.sizeX / 2, zximage.sizeY / 2)
    else
        graphic.setResolution(screen, zximage.sizeX, zximage.sizeY)
    end
end

function zximage.draw(screen, path, crop)
    local sleep = os.sleep
    local set = graphic.set
    if crop then
        return zximage.parse(path, function (x, y, back, fore, char)
            set(screen, ((x - 1) // 2) + 1, ((y - 1) // 2) + 1, back, fore, char, nil, true)
        end)
    else
        return zximage.parse(path, function (x, y, back, fore, char)
            if x == 1 and y % 8 == 0 then sleep(0) end
            set(screen, x, y, back, fore, char, nil, true)
        end)
    end
end

return zximage