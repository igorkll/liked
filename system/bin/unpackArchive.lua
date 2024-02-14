local fs = require("filesystem")
local archiver = require("archiver")
local liked = require("liked")
local gui = require("gui")
local screen, _, path = ...

local unpackFolder = gui_filepicker(screen, nil, nil, nil, nil, true, true, true)
if unpackFolder then
    gui.status(screen, nil, nil, "unpacking \"" .. gui.fpath(screen, path) .. "\" to \"" .. gui.fpath(screen, unpackFolder) .. "\"")
    fs.makeDirectory(unpackFolder)
    liked.assert(screen, archiver.unpack(path, unpackFolder))
end