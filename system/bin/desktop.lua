local graphic = require("graphic")
local computer = require("computer")
local event = require("event")
local calls = require("calls")
local unicode = require("unicode")
local programs = require("programs")
local gui_container = require("gui_container")
local fs = require("filesystem")
local paths = require("paths")

local colors = gui_container.colors

------------------------------------

local screen = ...
local rx, ry = graphic.findGpu(screen).getResolution()

local statusWindow = graphic.classWindow:new(screen, 1, 1, rx, 1)
local window = graphic.classWindow:new(screen, 1, 2, rx, ry - 1)

local wallpaperPath = "/data/wallpaper.t2p"
local userRoot = "/data/userdata/"
local userPath = userRoot
fs.makeDirectory(userRoot)

------------------------------------

local iconsX = 4
local iconsY = 2

local iconSizeX = 8
local iconSizeY = 4

local startIconsPoss = {}
local selectedIcons = {}

local icons

local function checkData()
    if not startIconsPoss[userPath] then
        startIconsPoss[userPath] = 1
    end
    if not selectedIcons[userPath] then
        selectedIcons[userPath] = 1
    end
end

local function drawStatus()
    local hours, minutes, seconds = calls.call("getRealTime", 3)
    hours = tostring(hours)
    minutes = tostring(minutes)
    if #hours == 1 then hours = "0" .. hours end
    if #minutes == 1 then minutes = "0" .. minutes end
    local str = hours .. ":" .. minutes

    statusWindow:fill(1, 1, rx, 1, colors.gray, 0, " ")
    statusWindow:set(window.sizeX - unicode.len(str), 1, colors.gray, colors.white, str)
    statusWindow:set(1, 1, colors.lightGray, colors.white, " OS ")
end

local function draw(old)
    checkData()

    drawStatus()
    window:clear(colors.lightBlue)

    window:set(1, window.sizeY - 3, colors.lightGray, colors.gray, " /")
    window:set(1, window.sizeY - 2, colors.lightGray, colors.gray, "/ ")
    window:set(1, window.sizeY - 1, colors.lightGray, colors.gray, "\\ ")
    window:set(1, window.sizeY - 0, colors.lightGray, colors.gray, " \\")

    window:set(3, window.sizeY - 3, colors.red, colors.gray, " /")
    window:set(3, window.sizeY - 2, colors.red, colors.gray, "/ ")
    window:set(3, window.sizeY - 1, colors.red, colors.gray, "\\ ")
    window:set(3, window.sizeY - 0, colors.red, colors.gray, " \\")

    window:set(window.sizeX - 1, window.sizeY - 3, colors.lightGray, colors.gray, "\\ ")
    window:set(window.sizeX - 1, window.sizeY - 2, colors.lightGray, colors.gray, " \\")
    window:set(window.sizeX - 1, window.sizeY - 1, colors.lightGray, colors.gray, " /")
    window:set(window.sizeX - 1, window.sizeY - 0, colors.lightGray, colors.gray, "/ ")

    if fs.exists(wallpaperPath) then
        local sx, sy = calls.call("gui_readimagesize", wallpaperPath)
        local ix, iy = ((window.sizeX / 2) - (sx / 2)) + 1, ((window.sizeY / 2) - (sy / 2)) + 1
        calls.call("gui_drawimage", screen, wallpaperPath, ix, iy)
    end

    local iconsCount = 0
    for i, v in ipairs(fs.list(userPath)) do
        iconsCount = iconsCount + 1
    end
    if startIconsPoss[userPath] >= iconsCount then
        startIconsPoss[userPath] = old or 1
    end

    icons = {}
    local count = 0
    for i, v in ipairs(fs.list(userPath)) do
        if i >= startIconsPoss[userPath] and i <= iconsCount then
            count = count + 1
            if count > (iconsX * iconsY) then
                break
            end

            local path = paths.concat(userPath, v) .. "/"
            local exp = paths.extension(path)
            local icon
            if exp and #exp > 0 then
                icon = paths.concat("/system/icons", exp .. ".t2p")
            elseif fs.isDirectory(path) then
                icon = "/system/icons/folder.t2p"
            end
            if not icon or not fs.exists(icon) then
                icon = "/system/icons/unkownfile.t2p"
            end

            table.insert(icons, {icon = icon, path = path, exp, index = i, name = v})
        end

        --[[
        local iconValue = i

        if iconValue > 0 then
            local pad = 16
            local padY = pad // 2
            local posX = (((iconValue * pad) - 1) % rx) + 1
            local posY = (((iconValue * pad) // rx) + 1) * padY
            local size = 10
            local sizeY = size // 2

            local drawPointX = posX - (size // 2)
            local drawPointY = posY - (sizeY // 2)
            if selectedIcon == i then
                window:fill(drawPointX - 1, drawPointY - 1, size + 2, sizeY + 1, colors.blue, 0, " ")
            end
            window:set(posX - (unicode.len(v) // 2), posY + sizeY - 2, colors.lightBlue, colors.white, v)
        end
        ]]
    end

    local count = 0
    for cx = 1, iconsX do
        for cy = 1, iconsY do
            count = count + 1
            local centerIconX = math.floor(((window.sizeX / (iconsX + 1)) * cx) + 0.5)
            local centerIconY = math.floor(((window.sizeY / (iconsY + 1)) * cy) + 0.5)
            local iconX = math.floor((centerIconX - (iconSizeX / 2)) + 0.5)
            local iconY = math.floor((centerIconY - (iconSizeY / 2)) + 0.5)
            local icon = icons[count]
            
            if icon then
                icon.iconX = iconX
                icon.iconY = iconY

                if selectedIcons[userPath] == icon.index then
                    window:fill(iconX - 2, iconY - 1, iconSizeX + 4, iconSizeY + 2, colors.blue, 0, " ")
                end
                local x, y = window:toRealPos(math.floor((centerIconX - (unicode.len(icon.name) / 2)) + 0.5), centerIconY + 2)
                calls.call("gui_drawtext", screen, x, y, colors.white, icon.name)
                --window:set(iconX - (unicode.len(icon.name) // 2), iconY + iconY - 2, colors.lightBlue, colors.white, icon.name)
                if icon.icon then
                    calls.call("gui_drawimage", screen, icon.icon, window:toRealPos(iconX, iconY))
                end
            end
        end
    end
end
draw()

local function listForward()
    checkData()

    local old = startIconsPoss[userPath]
    startIconsPoss[userPath] = startIconsPoss[userPath] + (iconsX * iconsY)
    draw(old)
end

local function listBack()
    checkData()

    startIconsPoss[userPath] = startIconsPoss[userPath] - (iconsX * iconsY)
    if startIconsPoss[userPath] < 1 then
        startIconsPoss[userPath] = 1
    end
    draw()
end

local function folderBack()
    userPath = paths.path(userPath)
    if unicode.sub(userPath, 1, unicode.len(userRoot)) ~= userPath then
        userPath = userRoot
    end
    draw()
end

local function fileDescriptor(icon)
    if fs.isDirectory(icon.path) then
        userPath = icon.path
        draw()
    elseif icon.exp == "t2p" then
        execute("paint", screen, icon.path)
    else
        warn("file is not supported")
    end
end

------------------------------------

local statusTimer
local function startStatusTimer()
    statusTimer = event.timer(10, function()
        drawStatus()
    end, math.huge)
end
local function stopStatusTimer()
    event.cancel(statusTimer)
end
startStatusTimer()

------------------------------------

function execute(name, ...)
    stopStatusTimer()
    local code, err = programs.load(name)
    local ok = true
    if code then
        local ok2, err2 = xpcall(code, debug.traceback, screen, ...)
        if not ok2 then
            err = err2
            ok = false
        end
    else
        ok = false
    end
    startStatusTimer()
    if not ok then
        draw()
        calls.call("gui_warn", screen, 1, 2, err or "unknown error")
    end
end

function saveZone()
    return calls.call("screenshot", screen, rx / 2 - 16, ry / 2 - 4, 33, 9)
end

function warn(str)
    local clear = saveZone()
    calls.call("gui_warn", screen, nil, nil, str)
    clear()
end

while true do
    local eventData = {computer.pullSignal()}
    local windowEventData = window:uploadEvent(eventData)
    local statusWindowEventData = statusWindow:uploadEvent(eventData)
    if statusWindowEventData[1] == "touch" then
        if statusWindowEventData[4] == 1 and statusWindowEventData[3] >= 1 and statusWindowEventData[3] <= 4 then
            local str, num = calls.call("gui_context", screen, 2, 2,
            {"  about", "  settings", "  paint(temp)", "------------------", "  shutdown", "  reboot"},
            {true, true, true, false, true, true})
            if num == 1 then
                execute("about")
            elseif num == 2 then
                execute("settings")
            elseif num == 3 then
                execute("paint", "/data/temp.t2p")
            elseif num == 5 then
                computer.shutdown()
            elseif num == 6 then
                computer.shutdown(true)
            end
            draw()
        end
    end

    if windowEventData[1] == "touch" then
        if windowEventData[4] >= window.sizeY - 3 then
            if windowEventData[3] >= 1 and windowEventData[3] <= 2 then
                listBack()
            elseif windowEventData[3] <= window.sizeX and windowEventData[3] >= window.sizeX - 1 then
                listForward()
            elseif windowEventData[3] >= 3 and windowEventData[3] <= 4 then
                folderBack()
            end
        end
        local iconCliked = false
        for i, v in ipairs(icons) do
            if windowEventData[3] >= v.iconX and windowEventData[3] < (v.iconX + iconSizeX) then
                if windowEventData[4] >= v.iconY and windowEventData[4] < (v.iconY + iconSizeY) then
                    iconCliked = true
                    if windowEventData[5] == 0 then
                        fileDescriptor(v)
                    else
                        local posX, posY = window:toRealPos(windowEventData[3], windowEventData[4])

                        local clear = calls.call("screenshot", screen, posX, posY, 19, 7)
                        local str, num = calls.call("gui_context", screen, posX, posY,
                        {"  open", "------------------", "  remove", "  rename", "  copy", "  cut"},
                        {true, false, true, true, true, true})
                        if num == 1 then
                            clear()
                            fileDescriptor(v)
                        elseif num == 3 then
                            local clear2 = saveZone()
                            local state = calls.call("gui_yesno", screen, nil, nil, "remove?")
                            clear2()

                            if state then
                                fs.remove(v.path)
                                draw()
                            else
                                clear()
                            end
                        elseif num == 4 then
                            local clear2 = saveZone()
                            local name = calls.call("gui_input", screen, nil, nil, "new name")
                            clear2()

                            if type(name) == "string" then
                                local path = paths.concat(userPath, name)
                                fs.rename(v.path, path)
                                draw()
                            else
                                clear()
                            end
                        else
                            clear()
                        end
                    end
                    break
                end
            end
        end
        if not iconCliked and windowEventData[5] == 1 then
            local posX, posY = window:toRealPos(windowEventData[3], windowEventData[4])

            local isRedraw
            local clear = calls.call("screenshot", screen, posX, posY, 19, 6)
            local str, num = calls.call("gui_context", screen, posX, posY,
            {"  back", "------------------", "  new image", "  new folder", "  paste"},
            {true, false, true, true, true})
            if num == 1 then
                folderBack()
                isRedraw = true
            elseif num == 3 then
                local clear = saveZone()
                local name = calls.call("gui_input", screen, nil, nil, "image name")
                clear()

                if type(name) == "string" then
                    local path = paths.concat(userPath, name .. ".t2p")
                    execute("paint", path)
                    draw()
                    isRedraw = true
                end
            elseif num == 4 then
                local clear = saveZone()
                local name = calls.call("gui_input", screen, nil, nil, "folder name")
                clear()

                if type(name) == "string" then
                    local path = paths.concat(userPath, name)
                    fs.makeDirectory(path)
                    draw()
                    isRedraw = true
                end
            end
            if not isRedraw then
                clear()
            end
        end
    end

    if eventData[1] == "redrawDesktop" then
        draw()
    end
end