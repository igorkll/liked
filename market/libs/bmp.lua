local fs = require("filesystem")
local graphic = require("graphic")
local bmp = {}

local function strToArray(str)
    local buffer = {}
    for i = 1, #str do
        table.insert(buffer, str:byte(i))
    end
    return buffer
end

local function get32bit(buffer)
    return buffer[1] | buffer[2] << 8 | buffer[3] << 16 | buffer[4] << 24
end

local function get16bit(buffer)
    return buffer[1] | buffer[2] << 8
end

local function getBits(buffer)
    local number = 0
    local bitOffset = 0
    for i = 1, #buffer do
        number = number | (buffer[i] << bitOffset)
        bitOffset = bitOffset + 8
    end
    return number
end

function bmp.parse(path, sizeCallback, callback)
    local file = fs.open(path, "rb")

    if file.read(2) ~= "BM" then
        error("not a BMP", 2)
    end

    local filesize = get32bit(strToArray(file.read(4)))
    file.read(4)
    local dataOffset = get32bit(strToArray(file.read(4)))

    -- DIB HEADER
    local dibHeaderSize = get32bit(strToArray(file.read(4)))
    local width = get32bit(strToArray(file.read(4)))
    local height = get32bit(strToArray(file.read(4)))
    local colorPlanes = get16bit(strToArray(file.read(2)))
    local bitsPerPixel = get16bit(strToArray(file.read(2)))
    local compressionType = get32bit(strToArray(file.read(4)))
    local imageSize = get32bit(strToArray(file.read(4)))
    file.read(4)
    file.read(4)
    local numOfColors = get32bit(strToArray(file.read(4)))
    local numOfImportantColors = get32bit(strToArray(file.read(4)))

    -- Colors Profile
    local redBitMask = get32bit(strToArray(file.read(4)))
    local greenBitMask = get32bit(strToArray(file.read(4)))
    local blueBitMask = get32bit(strToArray(file.read(4)))
    local alphaBitMask = get32bit(strToArray(file.read(4)))

    local colorSpace = get32bit(strToArray(file.read(4)))
    file.read(4 * 4 * 2)

    local gammaRed = get32bit(strToArray(file.read(4)))
    local gammaGreen = get32bit(strToArray(file.read(4)))
    local gammaBlue = get32bit(strToArray(file.read(4)))

    local intent = get32bit(strToArray(file.read(4)))
    local profileDataOffset = get32bit(strToArray(file.read(4)))
    local profileDataSize = get32bit(strToArray(file.read(4)))

    file.read(4)

    -- parsing
    sizeCallback(width, height)
    for ix = 1, width do
        for iy = height, 1, -1 do
            callback(ix, iy, getBits(strToArray(file.read(bitsPerPixel))))
        end
    end

    file.close()
    return true
end

function bmp.draw(screen, path)
    local gpu = graphic.findGpu(screen)
    local width, height
    bmp.parse(path, function (w, h)
        width, height = w, h
    end, function (x, y, color)
        gpu.setBackground(color)
        gpu.set(x, y, " ")
    end)
end

return bmp