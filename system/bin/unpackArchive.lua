local fs = require("filesystem")
local archiver = require("archiver")
local liked = require("liked")
local gui_container = require("gui_container")
local screen, _, path = ...

local unpackFolder = gui_filepicker(screen, nil, nil, nil, nil, true, true, true)
if unpackFolder then
    gui_status(screen, nil, nil, "unpacking \"" .. gui_container.toUserPath(screen, path) .. "\" to \"" .. gui_container.toUserPath(screen, unpackFolder) .. "\"")
    fs.makeDirectory(unpackFolder)
    liked.assert(screen, archiver.unpack(path, unpackFolder))
end