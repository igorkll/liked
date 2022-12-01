local graphic = require("graphic")
local gui_container = require("gui_container")
local paths = require("paths")
local fs = require("filesystem")
local unicode = require("unicode")
local event = require("event")

local colors = gui_container.colors

--------------------------------------------

local screen, cx, cy, dir, exp, save, dirmode = ...

local gpu = graphic.findGpu(screen)
local rx, ry = gpu.getResolution()

local devMode = gui_container.devModeStates[screen]
local userRoot = gui_container.userRoot
local userPath = dir or gui_container.userRoot

local function checkFolder()
    if unicode.sub(userPath, 1, unicode.len(userRoot)) ~= userRoot then
        userPath = userRoot
    end
end

if not cx or not cy then
    cx, cy = gpu.getResolution()
    cx = cx / 2
    cy = cy / 2
    cx = cx - 25
    cy = cy - 8
    cx = math.floor(cx + 0.5)
    cy = math.floor(cy + 0.5)
end

local window = graphic.createWindow(screen, cx, cy, 50, 16, true)
local reader = window:read(3, window.sizeY, 16, colors.black, colors.white)

--------------------------------------------

local strs
local function draw()
    window:clear(colors.gray)
    window:fill(1, 1, window.sizeX, 1, colors.lightGray, 0, " ")
    window:fill(1, window.sizeY, window.sizeX, 1, colors.lightGray, 0, " ")
    window:set(1, 1, colors.lightGray, colors.white, (save and "save " or "select ") .. (exp and (exp .. " ") or "") .. (dirmode and "directory" or "file"))

    window:set(window.sizeX, 1, colors.red, colors.white, "X")
    window:set(1, window.sizeY, colors.red, colors.white, "<")
    window:set(window.sizeX, window.sizeY, colors.green, colors.white, ">")

    window:set(20, window.sizeY, colors.lightGray, colors.white, paths.canonical(unicode.sub(userPath, unicode.len(userRoot), unicode.len(userPath))))

    reader.redraw()

    strs = {}
    local count = 1
    for i, file in ipairs(fs.list(userPath)) do
        if fs.isDirectory(paths.concat(userPath, file)) or ((not exp or paths.extension(file) == exp) and not dirmode) then
            window:fill(1, count + 1, window.sizeX, 1, colors.gray, 0, " ")
            window:set(1, count + 1, colors.gray, colors.white, file)
            strs[count] = file
            count = count + 1
        end
    end
end

draw()

while true do
    local eventData = {event.pull()}
    local windowEventData = window:uploadEvent(eventData)
    reader.uploadEvent(eventData)

    if windowEventData[1] == "touch" then
        local pos = windowEventData[4] - 1
        if strs[pos] then
            local filename = strs[pos]
            local fullpath = paths.concat(userPath, filename)
            if fs.isDirectory(fullpath) then
                if dirmode and windowEventData[5] == 1 then
                    if not save or gui_yesno(screen, nil, nil, "overwrite directory?") then
                        return fullpath
                    end
                else
                    userPath = fullpath
                end
            else
                if not save or gui_yesno(screen, nil, nil, "overwrite file?") then
                    return fullpath
                end
            end
            draw()
        end

        if windowEventData[3] == window.sizeX and windowEventData[4] == 1 then
            return
        end

        if windowEventData[3] == 1 and windowEventData[4] == window.sizeY then
            userPath = paths.path(userPath)
            checkFolder()
            draw()
        end

        if windowEventData[3] == window.sizeX and windowEventData[4] == window.sizeY then
            local filename = reader.getBuffer() .. (exp and ("." .. exp) or "")
            local filepath = paths.concat(userPath, filename)
            if (fs.exists(filepath) or save) and (not fs.exists(filepath) or fs.isDirectory(filepath) == not not dirmode) then
                return paths.concat(userPath, filename)
            else
                if fs.isDirectory(filepath) ~= not not dirmode then
                    if dirmode then
                        gui_warn(screen, nil, nil, "is not directory")
                    else
                        gui_warn(screen, nil, nil, "is directory")
                    end
                else
                    gui_warn(screen, nil, nil, (dirmode and "directory" or "file") .. " not found")
                end
                draw()
            end
        end
    end
end