local gui = require("gui")
local paths = require("paths")
local fs = require("filesystem")
local gui_container = require("gui_container")
local iowindows = {}

function iowindows.loadfile(screen)
    return gui_filepicker(screen)
end

function iowindows.selectfolder(screen)
    local list = {}
    for i, v in ipairs(fs.list(gui_container.defaultUserRoot)) do
        if fs.isDirectory(paths.concat(gui_container.defaultUserRoot, v)) then
            table.insert(list, paths.name(v))
        end
    end

    local num = gui.select(screen, nil, nil, "Select Folder", list)
    if num then
        return paths.concat(gui_container.defaultUserRoot, list[num])
    end
end

iowindows.unloadable = true
return iowindows