local fs = require("filesystem")
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

function bmp.parse(path, sizecallback, callback)
    local file = fs.open(path, "rb")

    if file.read(2) ~= "BM" then
        return nil, "not a BMP"
    end

    local filesize = get32bit(strToArray(file.read(4)))

    file.read(4)

    local dataOffset = get32bit(strToArray(file.read(4)))
end

return bmp