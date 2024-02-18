local graphic = require("graphic")
local liked = require("liked")
local iowindows = require("iowindows")
local fs = require("filesystem")
local screen = ...
local path = iowindows.selectfile(screen, "scr")
if fs.size(path) ~= 6912 then
    error("this file is not a picture from the ZX spectrum", 2)
end

graphic.setResolution(screen, 128, 48)

local reader = fs.open(path, "rb")
local rawPixels = {}
local pixels = {}
for y = 0, 191 do
    rawPixels[y] = reader.read(32)
end
local attributes = reader.read(768)
reader.close()







local function braille(b)
    local result = 0x2800;
    local b1 = (b & tonumber(00000001, 2)) << 7;
    local b2 = (b & tonumber(00000010, 2)) << 5;
    local b3 = (b & tonumber(00000100, 2)) << 3;
    local b4 = (b & tonumber(00001000, 2)) >> 1;
    local b5 = (b & tonumber(00010000, 2));
    local b6 = (b & tonumber(00100000, 2)) >> 4;
    local b7 = (b & tonumber(01000000, 2)) >> 3;
    local b8 = (b & tonumber(10000000, 2)) >> 7;
    return result + b1 + b2 + b3 + b4 + b5 + b6 + b7 + b8;
end

local function addr(y)
    local Y1 = y & tonumber(11000000, 2);
    local Y2 = (y & tonumber(00111000, 2)) >> 3;
    local Y3 = (y & tonumber(00000111, 2)) << 3;
    return Y1 + Y2 + Y3;
end










local backColors = {}
local foreColors = {}
local spectrumColorCodes = table.low{ 0, 1, 4, 5, 2, 3, 6, 7 }

for i = 0, 767 do
    backColors[i] = spectrumColorCodes[(attributes[i] & 56) >> 3]
    if (attributes[i] & 64) == 64 and backColors[i] ~= 0 then
        backColors[i] = backColors[i] + 8
    end

    foreColors[i] = spectrumColorCodes[attributes[i] & 7]
    if (attributes[i] & 64) == 64 and foreColors[i] ~= 0 then
        foreColors[i] = foreColors[i] + 8
    end
end

for i = 0, 191 do
    pixels[i] = rawPixels[addr(i)]
end

for l = 0, 47 do
    local buffer = {}
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
        local BackgroundColor = backColors[i / 4 + l / 2 * 32]
        local ForegroundColor = foreColors[i / 4 + l / 2 * 32]
        graphic.set(screen, i + 1, l + 1, BackgroundColor, ForegroundColor, braille(buffer[i]))
    end
end

graphic.forceUpdate()
liked.wait()