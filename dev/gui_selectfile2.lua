local graphic = require("graphic")
local gui_container = require("gui_container")
local event = require("event")
local unicode = require("unicode")
local fs = require("filesystem")
local paths = require("paths")

local colors = gui_container.colors

------------------------------------

local screen, cx, cy, mode, exp, standartDir, foldersMode = ...
foldersMode = not not foldersMode

local devMode = gui_container.devModeStates[screen]
local userRoot = devMode and "/" or "/data/userdata/"
local userPath = standartDir or "/data/userdata/"

local window = graphic.createWindow(screen, cx, cy, 50, 16, true)

local inputbox = window:read(1, window.sizeY - 1, window.sizeX - 16, colors.gray, colors.white)

local files

------------------------------------

local function draw()
    window:clear(colors.brown)
    window:set(1, 1, colors.brown, colors.green, mode .. " " .. (exp or "any") .. " " .. (foldersMode and "folder" or "file"))
    window:fill(1, 2, window.sizeX - 1, window.sizeY - 2)
    window:set(1, window.sizeY, colors.red, colors.white, "<+")
    window:set(window.sizeX - 2, window.sizeY, colors.green, colors.lime, "OK")
    inputbox.redraw()
end

local function tryPath(fullpath)
    local objIsDirectory = fs.isDirectory(fullpath)
    local objExists = fs.exists(fullpath)
    if mode == "save" then
        if objExists and objIsDirectory then
            gui_warn(screen, nil, nil, "the directory cannot be overwritten")
            draw()
            return
        end

        if objExists and not gui_yesno(screen, nil, nil, "overwrite the file?") then
            draw()
            return
        end
    elseif mode == "load" then
        if not objExists then
            gui_warn(screen, nil, nil, "file not found")
            draw()
            return
        end

        if objIsDirectory ~= foldersMode then
            gui_warn(screen, nil, nil, "is " .. (objIsDirectory and "folder" or "file"))
            draw()
            return
        end
    end

    return fullpath
end

local function tryName(name)
    local fullpath = paths.concat(userPath, name .. (exp and ("." .. exp) or ""))
    tryPath(fullpath)
end

local function refreshFiles()
    files = {}
    for i, file in ipairs(fs.list(userPath)) do
        table.insert(files, {
            fullpath = fs.concat(userPath, file),
            name = paths.hideExtension(file),
            typename = gui_container.typenames[paths.extension(files)] or paths.extension(file),
            color = gui_container.typecolors[paths.extension(files)] or colors.lightBlue
        })
    end
end

------------------------------------

while true do
    local eventData = {event.pull()}
    local windowEventData = window:uploadEvent(eventData)

    if inputbox then
        local input = inputbox.uploadEvent(windowEventData)
        if input == true then
            return
        elseif input then
            local path = tryName(input)
            if path then
                return path
            end
        end
    end

    if windowEventData[1] == "touch" then
        if windowEventData[4] == window.sizeY then
            if windowEventData[3] == 1 then
                userPath = paths.path(userPath)
                if unicode.sub(userPath, 1, unicode.len(userRoot)) ~= userRoot then
                    userPath = userRoot
                end
            elseif windowEventData[3] == 2 then
                local name = gui_warn()
            end
        end
    end
end