do return end

local fs = require("filesystem")

local file = fs.open("/image.t2p", "wb")
file.write(string.char(16))
file.write(string.char(8))
file.write("********")

for i = 1, 8 * 8 do
    file.write(string.char(101))
    file.write(string.char(1))
    file.write("+")
    file.write(string.char(86))
    file.write(string.char(1))
    file.write("-")
end

file.close()