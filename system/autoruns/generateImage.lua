local fs = require("filesystem")

local file = fs.open("/image.t2p", "rb")
file.write(string.char(16))
file.write(string.char(8))
file.write("********")

file.write(string.char(15))
file.write("+")
file.write(string.char(15))
file.write("-")

file.close()