local gui = require("gui")
local paths = require("paths")
local fs = require("filesystem")
local gui_container = require("gui_container")
local iowindows = {}

local function iowindow(screen, dirmode, exp, save)
    ---- title
    local title = ""
    if save then
        title = title .. "Save "
    else
        title = title .. "Select "
    end
    
    if exp then
        title = title .. (gui_container.typenames[exp] or exp) .. " "
    end

    if dirmode then
        title = title .. "Folder"
    else
        title = title .. "File"
    end

    ---- main
    local function process(root, path)
        local list = {{".. (back)", gui_container.colors.black, name = ".."}}
        for i, file in ipairs(fs.list(path)) do
            if fs.isDirectory(paths.concat(path, file)) or not dirmode then
                local name = paths.name(file)
                local lexp = paths.extension(name)
                if not exp or lexp == exp then
                    if exp then
                        name = paths.hideExtension(name)
                    end
                    table.insert(list, {name, gui_container.typecolors[lexp] or gui_container.colors.black, name = file})
                end
            end
        end
        
        local num, _, _, _, confirm = gui.select(screen, nil, nil, title, list)
        if num then
            local fullpath = paths.concat(path, list[num].name)
            local isDir = fs.isDirectory(fullpath)

            if isDir and not confirm then
                return process(root, fullpath)
            else
                if isDir == dirmode then
                    return fullpath
                else
                    local clear = gui.saveZone(screen)
                    gui.warn(screen, nil, nil, "it is impossible to select this object")
                    clear()
                end
            end
        else
            return true
        end
    end

    local result = process(gui_container.defaultUserRoot, gui_container.defaultUserRoot)
    if result ~= true then
        return result
    end
end


function iowindows.selectfile(screen, exp)
    return iowindow(screen, false, exp, false)
end

function iowindows.selectfolder(screen, exp)
    return iowindow(screen, true, exp, false)
end

function iowindows.savefile(screen, exp)
    return iowindow(screen, false, exp, true)
end

function iowindows.savefolder(screen, exp)
    return iowindow(screen, true, exp, true)
end

iowindows.unloadable = true
return iowindows