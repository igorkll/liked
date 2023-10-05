local paths = require("paths")
local fs = require("filesystem")
local gui_container = require("gui_container")

gui_container.openVia["afpx"] = nil
gui_container.typecolors["afpx"] = nil
gui_container.typenames["afpx"] = nil
gui_container.knownExps["afpx"] = nil

fs.remove("/data/icons/afpx.t2p")
fs.remove("/data/autoruns/archiver.lua")
fs.remove(paths.path(getPath()))