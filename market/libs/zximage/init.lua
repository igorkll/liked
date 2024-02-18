local serialization = require("serialization")
local system = require("system")
local fs = require("filesystem")
local graphic = require("graphic")
local zximage = {}
zximage.sizeX = 128
zximage.sizeY = 48
zximage.palettePath = system.getResourcePath("palette.plt")

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

    local function lolzAlloc(count)
        local tbl = {}
        for i = 0, count - 1 do
            tbl[i] = 0
        end
        return tbl
    end
    
    local function strToLolz(str)
        local tbl = {}
        for i = 1, #str do
            tbl[i - 1] = str:byte(i)
        end
        return tbl
    end
    
    local reader = fs.open(path, "rb")
    local rawPixels = {}
    local pixels = {}
    for y = 0, 191 do
        rawPixels[y] = strToLolz(reader.read(32))
    end
    local attributes = reader.read(768)
    reader.close()    
    
    local function braille(b)
        local result = 0x2800;
        local b1 = (b & tonumber("00000001", 2)) << 7;
        local b2 = (b & tonumber("00000010", 2)) << 5;
        local b3 = (b & tonumber("00000100", 2)) << 3;
        local b4 = (b & tonumber("00001000", 2)) >> 1;
        local b5 = (b & tonumber("00010000", 2));
        local b6 = (b & tonumber("00100000", 2)) >> 4;
        local b7 = (b & tonumber("01000000", 2)) >> 3;
        local b8 = (b & tonumber("10000000", 2)) >> 7;
        return result + b1 + b2 + b3 + b4 + b5 + b6 + b7 + b8;
    end
    
    local function addr(y)
        local Y1 = y & tonumber("11000000", 2);
        local Y2 = (y & tonumber("00111000", 2)) >> 3;
        local Y3 = (y & tonumber("00000111", 2)) << 3;
        return Y1 + Y2 + Y3;
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
    
    for i = 0, 191 do
        pixels[i] = rawPixels[addr(i)]
    end
    
    for l = 0, 47 do
        local buffer = lolzAlloc(128)
        for y = 0, 3 do
            for x = 0, 31 do
                local b = pixels[y + l * 4][x]
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
            local index = i // 4 + l // 2 * 32
            local BackgroundColor = backColors[index] or error(index)
            local ForegroundColor = foreColors[index] or error(index)
            callback(i + 1, l + 1, BackgroundColor, ForegroundColor, unicode.char(braille(buffer[i])))
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
    return zximage.parse(path, function (x, y, back, fore, char)
        if crop then
            graphic.set(screen, ((x - 1) // 2) + 1, ((y - 1) // 2) + 1, back, fore, char, nil, true)
        else
            graphic.set(screen, x, y, back, fore, char, nil, true)
        end

        if x == 1 and y % 8 == 1 then
            os.sleep(0)
        end
    end)
end

return zximage