local graphic = require("graphic")
local gui_container = require("gui_container")
local event = require("event")
local calls = require("calls")
local computer = require("computer")
local unicode = require("unicode")
local fs = require("filesystem")
local paths = require("paths")

local colors = gui_container.colors

------------------------------------
--mode1 == get file
--mode2 == save file
local screen, cx, cy, mode, exps, typename, expNames, standartFileName, standartDir, useFolders = ...
local gpu = graphic.findGpu(screen)
local rx, ry = gpu.getResolution()

local devMode = gui_container.devModeStates[screen]
local userRoot = _G.userRoot
local userPath = standartDir or _G.userRoot

local function checkFolder()
    if unicode.sub(userPath, 1, unicode.len(userRoot)) ~= userRoot then
        userPath = userRoot
    end
end

if type(exps) == "string" then
    exps = {exps}
end

if exps and #exps == 0 then
    exps = nil
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

local scroll = 0
local variantes = {}
local count = 0
local formatButtonPosX
local formatButtonSizeX
local okButtonPosX
local okButtonSizeX
local inputbox
local selectedExp = exps and exps[1]
if mode == 2 then
    inputbox = window:read(1, window.sizeY - 1, window.sizeX - 16, colors.gray, colors.white)
    inputbox.setBuffer(standartFileName or "")
end

local function isDirectory(path)
    return fs.isDirectory(path) and paths.extension(path) ~= "app"
end

local function findObjectName(path, noCheckFolder)
    if not noCheckFolder and isDirectory(path) then
        return "FOLDER"
    else
        if expNames and exps then
            local exp = paths.extension(path)
            for i, v in ipairs(exps) do
                if v == exp and expNames[i] then
                    return expNames[i]:upper()
                end
            end
        end
        return (paths.extension(path) or "absent"):upper()
    end
end

local function inTable(tbl, value)
    for i, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
end

local function draw()
    local zonesize = window.sizeY - 2
    if mode == 2 then
        zonesize = window.sizeY - 3
    end

    variantes = {}
    count = 0

    window:fill(2, 2, window.sizeX, window.sizeY, colors.gray, 0, " ")
    window:clear(colors.brown)
    window:set(window.sizeX, 1, colors.red, colors.white, "X")
    window:set(1, window.sizeY, colors.red, colors.white, "<")
    window:set(2, window.sizeY, colors.red, colors.white, "+")
    if devMode then
        window:set(window.sizeX - 7, 1, colors.brown, colors.lime, "devmode")
    end
    window:set(4, window.sizeY, colors.brown, colors.red, paths.canonical(unicode.sub(userPath, unicode.len(userRoot), unicode.len(userPath))))

    if mode == 1 then
        window:set(1, 1, colors.brown, colors.green, "select " .. typename)
    elseif mode == 2 then
        window:set(1, 1, colors.brown, colors.green, "select folder to save " .. typename)
    end

    window:fill(1, 2, window.sizeX, zonesize, colors.blue, 0, " ")
    window:fill(window.sizeX, 2, 1, zonesize, colors.orange, 0, " ")

    if mode == 2 then
        local str = findObjectName("0." .. (selectedExp or ""))
        formatButtonSizeX = unicode.len(str)
        formatButtonPosX = window.sizeX - 14
        window:set(formatButtonPosX, window.sizeY - 1, colors.red, colors.orange, str)

        local str = "OK"
        okButtonSizeX = unicode.len(str)
        okButtonPosX = window.sizeX - okButtonSizeX - 1
        window:set(okButtonPosX, window.sizeY - 1, colors.green, colors.lime, str)
    end

    local number = 2
    for _, file in ipairs(fs.list(userPath)) do
        local full_path = paths.concat(userPath, file)
        if isDirectory(full_path) or not exps or inTable(exps, paths.extension(file)) then
            if devMode or not isDirectory(full_path) or not paths.extension(file) then
                count = count + 1
                local posY = (number - scroll)
                if posY >= 2 and posY <= (zonesize + 1) then
                    table.insert(variantes, file)
                    local color
                    local exp = paths.extension(full_path)
                    if isDirectory(full_path) then
                        color = colors.yellow
                    else
                        if exp == "app" then
                            color = colors.red
                        elseif exp == "lua" then
                            color = colors.lime
                        elseif exp == "plt" then
                            color = colors.white
                        elseif exp == "t2p" then
                            color = colors.white
                        else
                            color = colors.lightBlue
                        end
                    end
                    window:fill(1, posY, window.sizeX - 1, 1, color, 0, " ")
                    local filename = paths.canonical(file)
                    if not devMode then
                        filename = paths.hideExtension(filename)
                    end
                    window:set(1, posY, color, 0, filename)
                    local expName = findObjectName(full_path)
                    window:set(window.sizeX - 2 - unicode.len(expName), posY, color, 0, expName)
                end
                number = number + 1
            end
        end
    end

    window:set(window.sizeX, math.floor(map(scroll, 0, count - 1, 2, zonesize + 1) + 0.5), colors.lime, 0, " ")

    if mode == 2 then
        inputbox.redraw()
    end
end
draw()

while true do
    local eventData = {event.pull()}
    local windowEventData = window:uploadEvent(eventData)
    if inputbox then
        local out = inputbox.uploadEvent(eventData)
        if okButtonPosX and windowEventData[4] == window.sizeY - 1 and windowEventData[3] >= okButtonPosX and windowEventData[3] < (okButtonPosX + okButtonSizeX) then
            if mode == 2 and #inputbox.getBuffer() > 0 then
                out = inputbox.getBuffer()
            end
        end
        if out then
            if out == true then
                return nil
            elseif #out > 0 then
                local path = paths.concat(userPath, selectedExp and (out .. "." .. selectedExp) or out)
                if (isDirectory(path) and not useFolders) or (not isDirectory(path) and useFolders) then
                    gui_warn(screen, nil, nil, "is " .. (isDirectory(path) and "directory" or "file"))
                    draw()
                else
                    if not fs.exists(path) or gui_yesno(screen, nil, nil, "replase this?") then
                        return path
                    end
                    draw()
                end
            end
        end
    end
    if windowEventData[1] == "touch" then
        if windowEventData[3] == window.sizeX and windowEventData[4] == 1 then
            return nil
        elseif windowEventData[3] == 1 and windowEventData[4] == window.sizeY then
            userPath = paths.path(userPath)
            scroll = 0
            checkFolder()
            draw()
        elseif windowEventData[3] == 2 and windowEventData[4] == window.sizeY then
            local result = gui_input(screen, nil, nil, "folder name")
            if result then
                if (not devMode and result:find("%.")) or result:find("%/") or result:find("%\\") then
                    gui_warn(screen, nil, nil, "error in name")
                else
                    local path = paths.concat(userPath, result)
                    if fs.exists(path) then
                        gui_warn(screen, nil, nil, "this name is occupied")
                    else
                        fs.makeDirectory(path)
                    end
                end
            end
            draw()
        elseif formatButtonPosX and windowEventData[4] == window.sizeY - 1 and windowEventData[3] >= formatButtonPosX and windowEventData[3] < (formatButtonPosX + formatButtonSizeX) then
            if mode == 2 then
                local strs = {}
                if not exps then
                    table.insert(strs, "  ABSENT  ")
                end
                local sizeX = 4
                if exps then
                    for i, v in ipairs(exps) do
                        table.insert(strs, "  " .. findObjectName("0." .. v, true) .. "  ")
                        if unicode.len(strs[#strs]) > sizeX then
                            sizeX = unicode.len(strs[#strs])
                        end
                    end
                end
                local sizeY = #strs + 1
                sizeX = sizeX + 1
                local posX, posY = window:toRealPos(windowEventData[3], windowEventData[4])
                posX, posY = findPos(posX, posY, sizeX, sizeY, rx, ry)
                local clear = screenshot(screen, posX, posY, sizeX, sizeY)
                local _, num = gui_context(screen, posX, posY, strs)
                clear()
                if num then
                    if exps then
                        selectedExp = exps[num]
                    else
                        selectedExp = nil
                    end
                    draw()
                end
            end
        elseif windowEventData[4] >= 2 and windowEventData[3] < window.sizeX then
            local filename = variantes[windowEventData[4] - 1]
            if filename then
                local full_path = paths.concat(userPath, filename)
                if isDirectory(full_path) then
                    if windowEventData[5] == 1 then
                        if inputbox then
                            inputbox.setBuffer(paths.hideExtension(paths.name(full_path)))
                            selectedExp = paths.extension(full_path)
                            draw()
                        else
                            return full_path
                        end
                    else
                        userPath = full_path
                        scroll = 0
                        draw()
                    end
                else
                    if mode == 1 and not windowEventData[5] == 1 then
                        return full_path
                    else
                        if inputbox then
                            inputbox.setBuffer(paths.hideExtension(paths.name(full_path)))
                            selectedExp = paths.extension(full_path)
                            draw()
                        end
                    end
                end
            end
        end
    elseif windowEventData[1] == "scroll" then
        if windowEventData[5] < 0 then
            if scroll < (count - 1) then
                scroll = scroll + 1
                draw()
            end
        else
            if scroll > 0 then
                scroll = scroll - 1
                draw()
            end
        end
    end
end