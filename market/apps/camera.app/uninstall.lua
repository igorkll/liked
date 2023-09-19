local paths = require("paths")
local fs = require("filesystem")
local gui_container = require("gui_container")

gui_container.openVia["cam"] = nil
gui_container.typecolors["cam"] = nil
gui_container.typenames["cam"] = nil
gui_container.knownExps["cam"] = nil

fs.remove("/data/icons/cam.t2p")
fs.remove("/data/autoruns/camera.lua")
fs.remove(paths.path(getPath()))