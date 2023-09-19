local graphic = require("graphic")
local gui_container = require("gui_container")
local paths = require("paths")
local fs = require("filesystem")
local unicode = require("unicode")
local computer = require("computer")

local colors = gui_container.colors

--------------------------------------------

local screen, cx, cy, dir, exp, save, dirmode, dircombine = ...

local gpu = graphic.findGpu(screen)
local rx, ry = gpu.getResolution()

local userPath = dir or gui_container.getUserRoot(screen)

--[[
local function isDev()
    return not not gui_container.devModeStates[screen]
end
]]

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

local scroll = 0
local maxScroll

local strs
local function draw()
    window:clear(colors.gray)
    window:fill(1, 1, window.sizeX, 1, colors.lightGray, 0, " ")
    window:fill(1, window.sizeY, window.sizeX, 1, colors.lightGray, 0, " ")
    window:set(1, 1, colors.lightGray, colors.white, (save and "save " or "select ") .. (exp and (exp .. " ") or "") .. (dirmode and "directory" or "file"))

    window:set(window.sizeX, 1, colors.red, colors.white, "X")
    window:set(1, window.sizeY, colors.red, colors.white, "<")
    window:set(2, window.sizeY, colors.red, colors.white, "+")
    window:set(window.sizeX, window.sizeY, colors.green, colors.white, ">")

    window:set(20, window.sizeY, colors.lightGray, colors.white, gui_container.shortPath(gui_container.toUserPath(screen, userPath), window.sizeX - 8 - 13))

    reader.redraw()

    strs = {}
    local count = 0
    for i, file in ipairs(fs.list(userPath)) do
        local dir = fs.isDirectory(paths.concat(userPath, file))
        if dir or ((not exp or paths.extension(file) == exp) and not dirmode) then
            local name = file
            if name:sub(#name, #name) == "/" then
                name = name:sub(1, #name - 1)
                file = file:sub(1, #file - 1)
            end
            local lexp = paths.extension(file)
            name = paths.hideExtension(name)

            --if (not dir or not lexp) or isDev() then
                local lname = (lexp and gui_container.typenames[lexp]) or lexp
                local ctype = (lname and ((dir and "DIR-" or "") .. lname) or (dir and "DIR" or "FILE")):upper()
                
                local objcolor = dir and colors.black or colors.lightGray
                if gui_container.typecolors[lexp] then
                    objcolor = gui_container.typecolors[lexp]
                end

                count = count + 1
                local pos = (count + 1) - scroll

                if pos > 1 and pos < window.sizeY then
                    window:fill(1, pos, window.sizeX, 1, objcolor, 0, " ")
                    window:set(1, pos, objcolor, colors.white, name)
                    window:set(window.sizeX - #ctype, pos, objcolor, colors.white, ctype)
                    strs[pos - 1] = file
                end
            --end
        end
    end
    maxScroll = count - 1
end

local function checkName(filename)
    local fullpath = paths.concat(userPath, filename)
    if (fs.exists(fullpath) or save) and (not fs.exists(fullpath) or fs.isDirectory(fullpath) == not not dirmode) then
        if fs.isDirectory(fullpath) then
            if not save or not fs.exists(fullpath) or gui_yesno(screen, nil, nil, (dircombine and "combine" or "overwrite") .. " directory?") then
                return fullpath
            end
        else
            if not save or not fs.exists(fullpath) or gui_yesno(screen, nil, nil, "overwrite file?") then
                return fullpath
            end
        end
        draw()
    else
        if fs.isDirectory(fullpath) ~= not not dirmode then
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

local function checkFileName(str)
    --return (not str:find("%.") or isDev()) and not str:find("%/") and not str:find("%\\") and #str > 0
    return not str:find("%/") and not str:find("%\\") and #str > 0
end

draw()

while true do
    local eventData = {computer.pullSignal()}
    local windowEventData = window:uploadEvent(eventData)

    local readResult = reader.uploadEvent(eventData)
    if readResult == true then
        return
    end

    if windowEventData[1] == "touch" then
        local pos = windowEventData[4] - 1
        if strs[pos] then
            if windowEventData[5] == 0 then
                --[[
                local ret = checkName(strs[pos])
                if ret then
                    return ret
                end
                ]]

                reader.setBuffer(paths.hideExtension(strs[pos]))
                reader.redraw()
            else
                local lpath = paths.concat(userPath, strs[pos])
                if fs.isDirectory(lpath) then
                    userPath = lpath
                    scroll = 0
                    draw()
                end                
            end
        end
        
        

        if windowEventData[3] == window.sizeX and windowEventData[4] == 1 then
            return
        end

        if windowEventData[3] == 2 and windowEventData[4] == window.sizeY then
            local str = gui_input(screen, nil, nil, "directory name")
            if str then
                if checkFileName(str) then
                    fs.makeDirectory(paths.concat(userPath, str))
                else
                    gui_warn(screen, nil, nil, "invalid name")
                end
            end
            draw()
        end

        if windowEventData[3] == 1 and windowEventData[4] == window.sizeY then
            userPath = gui_container.checkPath(screen, paths.path(userPath))
            scroll = 0
            draw()
        end
    elseif windowEventData[1] == "scroll" then
        if windowEventData[5] > 0 then
            scroll = scroll - 1
        else
            scroll = scroll + 1
        end

        if scroll < 0 then
            scroll = 0
        elseif scroll > maxScroll then
            scroll = maxScroll
        else
            draw()
        end
    end

    if (windowEventData[1] == "touch" and windowEventData[3] == window.sizeX and windowEventData[4] == window.sizeY) or (readResult and readResult ~= true) then
        local buff = reader.getBuffer()

        if checkFileName(buff) then
            local filename = buff .. (exp and ("." .. exp) or "")
            local ret = checkName(filename)
            if ret then
                return ret
            end
        else
            gui_warn(screen, nil, nil, "invalid name")
            draw()
        end
    end
end