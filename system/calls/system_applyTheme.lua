local fs = require("filesystem")
local calls = require("calls")
local gui_container = require("gui_container")
local path = ...

local file = assert(fs.open(path, "rb"))
local data = file.readAll()
file.close()

local tbl = calls.call("unserialization", data)
gui_container.indexsColors = tbl
gui_container.colors = {
    white     = tbl[1],
    orange    = tbl[2],
    magenta   = tbl[3],
    lightBlue = tbl[4],
    yellow    = tbl[5],
    lime      = tbl[6],
    pink      = tbl[7],
    gray      = tbl[8],
    lightGray = tbl[9],
    cyan      = tbl[10],
    purple    = tbl[11],
    blue      = tbl[12],
    brown     = tbl[13],
    green     = tbl[14],
    red       = tbl[15],
    black     = tbl[16]
}