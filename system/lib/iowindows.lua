local gui = require("gui")
local paths = require("paths")
local fs = require("filesystem")
local gui_container = require("gui_container")
local text = require("text")
local iowindows = {}

local function iowindow(screen, dirmode, exp, save)
    ---- title
    local title = ""
    if save then
        title = title .. "save "
    else
        title = title .. "select "
    end
    
    if exp then
        title = title .. (gui_container.typenames[exp] or exp) .. " "
    end

    if dirmode then
        title = title .. "folder"
    else
        title = title .. "file"
    end

    ---- main
    local path = gui_container.defaultUserRoot

    while true do
        local list = {{".. (back / current)", gui_container.colors.black, name = ".."}}
        for i, file in ipairs(fs.list(path)) do
            local isDir = fs.isDirectory(paths.concat(path, file))
            if isDir or not dirmode then
                local name = paths.name(file)
                local lexp = paths.extension(name)
                if isDir or not exp or lexp == exp then
                    local hide
                    if exp and not gui_container.hiddenFiles[screen] then
                        hide = true
                        name = paths.hideExtension(name)
                    end
                    local function f(str)
                        if not hide then
                            return str
                        end
                        return str .. (lexp and ((gui_container.typenames[lexp] or lexp) .. "-") or "")
                    end
                    if isDir then
                        name = f("D-") .. name
                    else
                        name = f("F-") .. name
                    end
                    table.insert(list, {name, gui_container.typecolors[lexp] or gui_container.colors.black, name = file})
                end
            end
        end
        
        local num, _, _, _, confirm = gui.select(screen, nil, nil, title, list)
        if num then
            local fullpath = paths.concat(path, list[num].name)
            local isDir = fs.isDirectory(fullpath)
            local lexp = paths.extension(fullpath)

            if isDir and not confirm then
                path = gui_container.checkPath(screen, fullpath)
            else
                if isDir == dirmode and (not exp or lexp == exp) then
                    return fullpath
                else
                    gui.warn(screen, nil, nil, "select the " .. (dirmode and "folder" or "file") .. (exp and (" with the " .. exp .. " extension") or ""))
                end
            end
        else
            return
        end
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