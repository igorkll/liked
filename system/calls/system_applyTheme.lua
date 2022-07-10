local fs = require("filesystem")
local serialization = require("serialization")
local path = ...

local file = assert(fs.open(path, "rb"))
local data = file.readAll()
file.close()

local tbl = serialization.unserialize(data)