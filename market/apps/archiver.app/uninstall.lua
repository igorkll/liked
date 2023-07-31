local paths = require("paths")
local fs = require("filesystem")

fs.remove(paths.path(getPath()))
fs.remove("/data/icons/afpx.t2p")