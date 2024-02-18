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
    byte[] buffer = new byte[128]
    for (int y = 0 y < 4 y++)
    {
        for (int x = 0 x < 32 x++)
        {
            byte b = pixels[y + l * 4][x]
            for (int i = 3 i >= 0 i--)
            {
                buffer[i + x * 4] += (byte)(b & 0b11)
                b >>= 2
                if (y < 3)
                    buffer[i + x * 4] <<= 2
            }
        }
    }

    for (int i = 0 i < 128 i++)
    {
        Console.BackgroundColor = (ConsoleColor)backColors[i / 4 + l / 2 * 32]
        Console.ForegroundColor = (ConsoleColor)foreColors[i / 4 + l / 2 * 32]
        Console.Write(braille(buffer[i]))
    }
    Console.BackgroundColor = ConsoleColor.Black
    Console.ForegroundColor = ConsoleColor.White
    Console.WriteLine()
end

graphic.forceUpdate()
liked.wait()