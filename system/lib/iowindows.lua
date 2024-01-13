local gui = require("gui")
local paths = require("paths")
local fs = require("filesystem")
local gui_container = require("gui_container")
local text = require("text")
local format = require("format")
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
    local pathPos = 5 + (save and 16 or 0)
    local reader

    local function retpathFunc(list, num, fullpath, confirm)
        local isDir = num == 1 or fs.isDirectory(fullpath)
        local lexp = paths.extension(fullpath)

        if isDir and not confirm then
            path = gui_container.checkPath(screen, fullpath)
        else
            if isDir == dirmode and (not exp or lexp == exp) then
                local retpath = fullpath
                if num and list and list[num].name == ".." then
                    retpath = paths.canonical(path)
                end
                if save then
                    if isDir == dirmode then
                        if gui.yesno(screen, nil, nil, "are you sure you want to " .. (isDir and "merge the directory?" or "overwrite the file?")) then
                            return retpath
                        end
                    else
                        gui.warn(screen, nil, nil, "you should choose " .. (dirmode and "folder" or "file") .. " instead of " .. (dirmode and "folder" or "file"))
                    end
                else
                    return retpath
                end
            else
                gui.warn(screen, nil, nil, "select the " .. (dirmode and "folder" or "file") .. (exp and (" with the " .. exp .. " extension") or ""))
            end
        end
    end

    while true do
        local list = {{".. (back / current)", gui_container.colors.black, name = ".."}}
        for i, file in ipairs(fs.list(path)) do
            local isDir = fs.isDirectory(paths.concat(path, file))
            if isDir or not dirmode then
                local name = paths.name(file)
                local lexp = paths.extension(name)
                if isDir or not exp or lexp == exp then
                    if not gui_container.viewFileExps[screen] then
                        name = paths.hideExtension(name)
                    end

                    local smartString = format.smartConcat()
                    smartString.add(1, name)
                    smartString.add(47, (lexp and ((gui_container.typenames[lexp] or lexp) .. "-") or "") .. (isDir and " DIR" or "FILE"), true)
                    table.insert(list, {smartString.get(), gui_container.typecolors[lexp] or gui_container.colors.black, name = file})
                end
            end
        end
        
        local num, _, _, _, confirm = gui.select(screen, nil, nil, title, list, nil, nil, function (window)
            window:set(1, window.sizeY, gui_container.colors.red, gui_container.colors.white, " + ")
            window:set(pathPos, window.sizeY, gui_container.colors.lightGray, gui_container.colors.white, gui_container.short(gui_container.toUserPath(screen, path), 21))
            if not reader then
                reader = window:read(5, window.sizeY, 16, gui_container.colors.white, gui_container.colors.gray, nil, nil, nil, true)
            else
                reader.redraw()
            end
        end, function (windowEventData, window)
            if reader then
                reader.uploadEvent(windowEventData)
            end

            if windowEventData[1] == "touch" then
                if windowEventData[4] == window.sizeY and windowEventData[3] <= 3 then
                    local clear = gui.saveZone(screen)
                    local name = gui.input(screen, nil, nil, "folder name")
                    clear()

                    if name then
                        fs.makeDirectory(paths.concat(path, name))
                        return true
                    end
                end
            end
        end)

        if num then
            if num ~= true then
                local fullpath = paths.concat(path, list[num].name)
                local retpath = retpathFunc(list, num, fullpath, confirm)
                if retpath then
                    return retpath
                end
            end
        elseif ( confirm) and reader then
            local buff = reader.getBuffer()
            local ret = retpathFunc(nil, nil, paths.concat(path, buff .. (exp and ("." .. exp) or "")), true)
            if ret then
                return ret
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