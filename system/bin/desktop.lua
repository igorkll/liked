--ВНИМАНИЯ, для кономии оперативной памяти, я загружаю данный файл один раз и создаю на него патоки
--соответственно таблица _ENV для всех desktop обшая, и тут нельзя использовать глобалы
local warn, saveZone, execute

local graphic = require("graphic")
local computer = require("computer")
local event = require("event")
local calls = require("calls")
local unicode = require("unicode")
local programs = require("programs")
local gui_container = require("gui_container")
local fs = require("filesystem")
local paths = require("paths")
local component = require("component")
local sha256 = require("sha256").sha256

local colors = gui_container.colors

------------------------------------

local screen = ...
local rx, ry = graphic.findGpu(screen).getResolution()

local statusWindow = graphic.createWindow(screen, 1, 1, rx, 1)
local window = graphic.createWindow(screen, 1, 2, rx, ry - 1)

local wallpaperPath = "/data/wallpaper.t2p"
--[[
local userRoot = "/data/userdata/"
local userPath = userRoot
]]
local userRootMain = "/data/userdata/"
local userRoot = userRootMain
local userPath = userRootMain
local iconsPath = userRootMain
local iconAliases = {
    "/system/bin/about.app",
    "/system/bin/settings.app",
    "/system/bin/update.app",
    "/system/bin/market.app"
}
local usrBin = "/data/bin"
local timeZonePath = "/data/timeZone.dat"
local passwordFilePath = "/data/password.sha256"

fs.makeDirectory(userRoot)
fs.makeDirectory(userPath)

------------------------------------

local iconsX = 4
local iconsY = 2
local lockFlag = false

if rx == 160 and ry == 50 then
    iconsX = 8
    iconsY = 4
end

local iconSizeX = 8
local iconSizeY = 4

local startIconsPoss = {}
--local selectedIcons = {}

local redrawFlag = false
event.listen("redrawDesktop", function()
    redrawFlag = true
end)

local icons

local copyObject
local isCut = false

local devMode = false

local function checkData()
    if not startIconsPoss[paths.canonical(userPath)] then
        startIconsPoss[paths.canonical(userPath)] = 1
    end
end

local contextMenuOpen = false
local function drawStatus()
    local timeZone = _G.timeZone or 3
    if not _G.timeZone then
        if fs.exists(timeZonePath) then
            local file = fs.open(timeZonePath, "rb")
            local data = tonumber(file.readAll())
            file.close()
            if data then
                timeZone = data
            end
        end
    end
    _G.timeZone = timeZone or 3
    timeZone = _G.timeZone
    
    local hours, minutes, seconds = calls.call("getRealTime", timeZone)
    hours = tostring(hours)
    minutes = tostring(minutes)
    if #hours == 1 then hours = "0" .. hours end
    if #minutes == 1 then minutes = "0" .. minutes end

    local gameHours, gameMinutes = calls.call("getGameTime")
    gameHours = tostring(gameHours)
    gameMinutes = tostring(gameMinutes)
    if #gameHours == 1 then gameHours = "0" .. gameHours end
    if #gameMinutes == 1 then gameMinutes = "0" .. gameMinutes end

    local str = "real time: " .. hours .. ":" .. minutes .. "   game time: " .. gameHours .. ":" .. gameMinutes .. "   " .. tostring(math.floor(calls.call("map", computer.energy(), 0, computer.maxEnergy(), 0, 100) + 0.5)) .. "%"

    statusWindow:fill(1, 1, rx, 1, colors.gray, 0, " ")
    statusWindow:set(window.sizeX - unicode.len(str), 1, colors.gray, colors.white, str)
    if not lockFlag then
        statusWindow:set(1, 1, contextMenuOpen and colors.blue or colors.lightGray, colors.white, " OS ")
    end
end

local function draw(old)
    redrawFlag = false
    checkData()

    drawStatus()
    window:clear(colors.lightBlue)
    if fs.exists(wallpaperPath) then
        local sx, sy = calls.call("gui_readimagesize", wallpaperPath)
        local ix, iy = math.floor(((window.sizeX / 2) - (sx / 2)) + 0.5) + 1, math.floor(((window.sizeY / 2) - (sy / 2)) + 0.5) + 1
        ix, iy = window:toRealPos(ix, iy)
        pcall(calls.call, "gui_drawimage", screen, wallpaperPath, ix, iy)
    end

    local str = "path: " .. unicode.sub(userPath, unicode.len(userRoot), unicode.len(userPath))
    window:set(math.floor(((window.sizeX / 2) - (unicode.len(str) / 2)) + 0.5),
    window.sizeY, colors.lightGray, colors.gray, str)

    window:set(1, window.sizeY - 3, colors.lightGray, colors.white, " /")
    window:set(1, window.sizeY - 2, colors.lightGray, colors.white, "/ ")
    window:set(1, window.sizeY - 1, colors.lightGray, colors.white, "\\ ")
    window:set(1, window.sizeY - 0, colors.lightGray, colors.white, " \\")

    window:set(3, window.sizeY - 3, colors.red, colors.white, " /")
    window:set(3, window.sizeY - 2, colors.red, colors.white, "/ ")
    window:set(3, window.sizeY - 1, colors.red, colors.white, "\\ ")
    window:set(3, window.sizeY - 0, colors.red, colors.white, " \\")

    window:set(window.sizeX - 1, window.sizeY - 3, colors.lightGray, colors.white, "\\ ")
    window:set(window.sizeX - 1, window.sizeY - 2, colors.lightGray, colors.white, " \\")
    window:set(window.sizeX - 1, window.sizeY - 1, colors.lightGray, colors.white, " /")
    window:set(window.sizeX - 1, window.sizeY - 0, colors.lightGray, colors.white, "/ ")

    local iconsCount = 0
    local tbl = fs.list(userPath)
    if not tbl then
        userPath = userRootMain
        return draw()
    end
    for i, v in ipairs(tbl) do
        iconsCount = iconsCount + 1
    end

    if paths.canonical(userPath) == paths.canonical(iconsPath) then
        for i, v in ipairs(iconAliases) do
            if fs.exists(v) then
                iconsCount = iconsCount + 1
            end
        end
        for i, file in ipairs(fs.list(usrBin) or {}) do
            iconsCount = iconsCount + 1
        end
    end

    local lUserPath = paths.canonical(userPath)
    if startIconsPoss[lUserPath] > iconsCount then
        startIconsPoss[lUserPath] = old or 1
    end

    local str = tostring(math.floor(startIconsPoss[lUserPath] // (iconsX * iconsY)) + 1) .. "/" ..
    tostring(math.floor((iconsCount - 1) // (iconsX * iconsY)) + 1)
    window:set(math.floor(((window.sizeX / 2) - (unicode.len(str) / 2)) + 0.5), window.sizeY - 1, colors.lightGray, colors.gray, str)

    icons = {}
    local count = 0

    local gui_readimagesize = calls.load("gui_readimagesize")

    local function addIcon(i, v, customPath)
        count = count + 1
        if count > (iconsX * iconsY) then
            return true
        end

        local path, preName
        if customPath then
            path = customPath
        else
            path = paths.concat(userPath, v)
        end
        local exp = paths.extension(path)
        local icon
        local readonly
        local labelReadonly
        local isFs
        local fsd
        if fs.isDirectory(path) and fs.exists(paths.concat(path, "icon.t2p")) then
            icon = paths.concat(path, "icon.t2p")
        elseif exp and #exp > 0 and exp ~= "app" and exp ~= "t2p" then
            icon = paths.concat("/system/icons", exp .. ".t2p")
        elseif exp == "app" then
            icon = "/system/icons/app.t2p"
        elseif fs.isDirectory(path) then
            icon = "/system/icons/folder.t2p"

            for _, tbl in ipairs(fs.mountList) do
                if paths.canonical(path) .. "/" == tbl[2] then
                    isFs = true
                    fsd = tbl[1]
                    readonly = fsd.isReadOnly()
                    labelReadonly = not pcall(fsd.setLabel, fsd.getLabel() or nil) --getLabel может вернуть no value, который отличаеться от nil в данном случаи
                    local info = computer.getDeviceInfo()[fsd.address]
                    if not info then
                        event.sleep(2)
                    end
                    local clock = info and info.clock
                    local iconpath = paths.concat(path, "external-data/devivetype.dat")
                    if fs.exists(iconpath) then
                        local file = fs.open(iconpath, "rb")
                        local data = file.readAll()
                        file.close()

                        icon = paths.concat("/system/icons", data .. ".t2p")
                        preName = (component.invoke(fsd.address, "getLabel") or data) .. "-" .. fsd.address:sub(1, 5)
                    elseif fsd.address == computer.tmpAddress() then
                        icon = "/system/icons/tmp.t2p"
                    elseif clock == "20/20/20" then
                        icon = "/system/icons/fdd.t2p"
                    else
                        icon = "/system/icons/hdd.t2p"
                    end
                    break
                end
            end
        elseif exp == "t2p" then
            icon = "/system/icons/t2p.t2p"
            local iconPath = path

            if iconPath then
                local ok, sx, sy = pcall(gui_readimagesize, iconPath)
                if ok and sx == 8 and sy == 4 then
                    icon = iconPath
                end
            end
        end
        do
            local ok, sx, sy = pcall(gui_readimagesize, icon)
            if not ok or sx ~= 8 or sy ~= 4 then
                icon = nil
            end
        end
        if not icon or not fs.exists(icon) then
            icon = "/system/icons/unkownfile.t2p"
        end

        local name = preName
            if not name then
            if devMode then
                name = paths.name(path)
            else
                name = paths.name(paths.hideExtension(path))
            end
        end
        table.insert(icons, {fs = fsd, readonly = readonly, isFs = isFs, labelReadonly = labelReadonly, icon = icon, path = path, exp = exp, index = i, name = name, isAlias = not not customPath, isDir = fs.isDirectory(path)})
    end

    local tbl = {}

    if paths.canonical(userPath) == paths.canonical(iconsPath) then
        for i, v in ipairs(iconAliases) do
            if fs.exists(v) then
                table.insert(tbl, {nil, v})
            end
        end
        for i, file in ipairs(fs.list(usrBin) or {}) do
            table.insert(tbl, {nil, paths.concat(usrBin, file)})
        end
    end

    for i, v in ipairs(fs.list(userPath)) do
        table.insert(tbl, {v})
    end

    for i, v in ipairs(tbl) do
        if i >= startIconsPoss[lUserPath] and i <= iconsCount then
            if addIcon(i, v[1], v[2]) then
                break
            end
        end
    end

    local gui_drawtext = calls.load("gui_drawtext")
    local gui_drawimage = calls.load("gui_drawimage")

    local count = 0
    for cy = 1, iconsY do
        for cx = 1, iconsX do
            count = count + 1
            local centerIconX = math.floor(((window.sizeX / (iconsX + 1)) * cx) + 0.5)
            local centerIconY = math.floor(((window.sizeY / (iconsY + 1)) * cy) + 0.5)
            local iconX = math.floor((centerIconX - (iconSizeX / 2)) + 0.5)
            local iconY = math.floor((centerIconY - (iconSizeY / 2)) + 0.5)
            local icon = icons[count]
            
            if icon then
                icon.iconX = iconX
                icon.iconY = iconY

                --if selectedIcons[userPath] == icon.index then
                --    window:fill(iconX - 2, iconY - 1, iconSizeX + 4, iconSizeY + 2, colors.blue, 0, " ")
                --end
                local x, y = window:toRealPos(math.floor((centerIconX - (unicode.len(icon.name) / 2)) + 0.5), centerIconY + 2)
                gui_drawtext(screen, x, y, colors.white, icon.name)
                --window:set(iconX - (unicode.len(icon.name) // 2), iconY + iconY - 2, colors.lightBlue, colors.white, icon.name)
                if icon.icon then
                    pcall(gui_drawimage, screen, icon.icon, window:toRealPos(iconX, iconY))
                end
            end
        end
    end
end

local function listForward()
    checkData()

    local lUserPath = paths.canonical(userPath)
    local old = startIconsPoss[lUserPath]
    startIconsPoss[lUserPath] = startIconsPoss[lUserPath] + (iconsX * iconsY)
    draw(old)
end

local function listBack()
    checkData()

    local lUserPath = paths.canonical(userPath)
    startIconsPoss[lUserPath] = startIconsPoss[lUserPath] - (iconsX * iconsY)
    if startIconsPoss[lUserPath] < 1 then
        startIconsPoss[lUserPath] = 1
    end
    draw()
end

local function checkFolder()
    if unicode.sub(userPath, 1, unicode.len(userRoot)) ~= userRoot then
        userPath = userRoot
    end
end

local function folderBack()
    userPath = paths.path(userPath)
    checkFolder()
    draw()
end

local function fileDescriptor(icon, alternative, nikname)
    if alternative then
        if fs.isDirectory(icon.path) then
            userPath = icon.path
            draw()
            return true
        elseif icon.exp == "lua" then
            execute("edit", icon.path)
            draw()
            return true
        end
    end

    if icon.exp == "app" then
        if fs.isDirectory(icon.path) then
            execute(paths.concat(icon.path, "main.lua"), nikname)
        else
            execute(icon.path, nikname)
        end
        draw()
        return true
    elseif fs.isDirectory(icon.path) then
        userPath = icon.path
        draw()
        return true
    elseif icon.exp == "t2p" then
        execute("paint", icon.path)
        draw()
        return true
    elseif icon.exp == "lua" then
        execute(icon.path, nikname)
        draw()
        return true
    elseif icon.exp == "plt" then
        local clear = saveZone()
        local state = calls.call("gui_yesno", screen, nil, nil, "apply this theme?")
        clear()

        if state then
            calls.call("system_setTheme", icon.path)
            event.push("redrawDesktop")
        end
    elseif icon.exp == "txt" or icon.exp == "log" or (icon.exp == "dat" and devMode) then
        execute("edit", icon.path, icon.exp == "log")
        draw()
    elseif icon.exp == "mid" or icon.exp == "midi" then
        if programs.find("midi") then
            execute("midi", nikname, icon.path)
            draw()
        else
            local clear = saveZone()
            warn("pleas, download programm midi from market")
            clear()
        end
    elseif icon.exp == "dfpwm" then
        if programs.find("tape") then
            execute("tape", nikname, icon.path)
            draw()
        else
            local clear = saveZone()
            warn("pleas, download programm tape from market")
            clear()
        end
    else
        warn("file is not supported")
    end
end

local function setDevMode(state)
    if state == devMode then return end
    if state then
        userRoot = "/"
    else
        userRoot = userRootMain
    end
    devMode = state
    checkFolder()
    draw()
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

function execute(name, ...) --локалезирована выше
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

local function addExp(name, exp)
    if not devMode then
        return name .. "." .. exp
    else
        local realexp = paths.extension(name)
        if not realexp or realexp == "" then
            name = name .. "." .. exp
        end
        return name
    end
end

local devModeCount = 0
local devModeResetTime = 0

event.listen("key_down", function(_, uuid, char, code)
    if devMode then
        local ok
        for i, v in ipairs(component.invoke(screen, "getKeyboards")) do
            if v == uuid then
                ok = true
            end
        end
        if ok then
            if char == 0 and code == 46 then
                event.interruptFlag = true
            end
        end
    end
end)

local function lock()
    local file = fs.open(passwordFilePath, "rb")
    local passwordHesh = file.readAll()
    file.close()

    lockFlag = true
    drawStatus()

    while true do
        window:clear(colors.lightBlue)
        local data = gui_input(screen, nil, nil, "enter password", true)
        if data then
            if sha256(data) == passwordHesh then
                break
            else
                gui_warn(screen, nil, nil, "uncorrent password")
            end
        else
            if gui_yesno(screen, nil, nil, "shutdown?") then
                computer.shutdown()
            end
        end
    end

    lockFlag = false
    drawStatus()
end
if fs.exists(passwordFilePath) then
    lock()
end
draw()

while true do
    if redrawFlag then
        draw()
    end
    local eventData = {computer.pullSignal(0.5)}
    local windowEventData = window:uploadEvent(eventData)
    local statusWindowEventData = statusWindow:uploadEvent(eventData)
    if statusWindowEventData[1] == "touch" then
        if statusWindowEventData[4] == 1 and statusWindowEventData[3] >= 1 and statusWindowEventData[3] <= 4 then
            contextMenuOpen = true
            drawStatus()
            local clear = calls.call("screenshot", screen, 2, 2, 19, 7)
            local str, num = calls.call("gui_context", screen, 2, 2,
            {"  about", "  settings", "  unlogin", "------------------", "  shutdown", "  reboot"},
            {true, true, fs.exists(passwordFilePath), false, true, true})
            contextMenuOpen = false
            drawStatus()
            if num == 1 then
                execute("about")
                draw()
            elseif num == 2 then
                execute("settings")
                draw()
            elseif num == 3 then
                lock()
                draw()
            elseif num == 5 then
                computer.shutdown()
            elseif num == 6 then
                computer.shutdown(true)
            else
                clear()
            end
        end
    end

    if windowEventData[1] == "touch" then
        if windowEventData[4] >= window.sizeY - 3 then
            if windowEventData[3] >= 1 and windowEventData[3] <= 2 then
                listBack()
                goto bigSkip
            elseif windowEventData[3] <= window.sizeX and windowEventData[3] >= window.sizeX - 1 then
                listForward()
                goto bigSkip
            elseif windowEventData[3] >= 3 and windowEventData[3] <= 4 then
                folderBack()
                goto bigSkip
            end
        end
        local iconCliked = false
        for i, v in ipairs(icons) do
            if windowEventData[3] >= v.iconX and windowEventData[3] < (v.iconX + iconSizeX) then
                if windowEventData[4] >= v.iconY and windowEventData[4] < (v.iconY + iconSizeY) then
                    --selectedIcons[userPath] = v.index
                    --draw()
                    
                    iconCliked = true
                    if windowEventData[5] == 0 then
                        fileDescriptor(v, nil, windowEventData[6])
                    else
                        if v.isFs then
                            local screenshotY = 6
                            local strs, active =
                            {"  open", "----------------------", "  format", "  set label", "  clear label"},
                            {true, false, not v.readonly, not v.labelReadonly, not v.labelReadonly}

                            local posX, posY = window:toRealPos(windowEventData[3], windowEventData[4])

                            local clear = calls.call("screenshot", screen, posX, posY, 23, screenshotY)
                            local str, num = calls.call("gui_context", screen, posX, posY,
                            strs, active)

                            if num == 1 then
                                fileDescriptor(v, nil, windowEventData[6])
                            elseif num == 3 then
                                local clear2 = saveZone()
                                local state = calls.call("gui_yesno", screen, nil, nil, "format?")
                                clear2()
                                clear()

                                if state then
                                    v.fs.remove("/")
                                end
                            elseif num == 4 then
                                local clear2 = saveZone()
                                local newlabel = calls.call("gui_input", screen, nil, nil, "new label")

                                if newlabel then
                                    if not pcall(v.fs.setLabel, newlabel) then
                                        clear2()
                                        clear()
                                        warn("error in name")
                                    else
                                        draw()
                                    end
                                else
                                    clear2()
                                    clear()
                                end
                            elseif num == 5 then
                                local clear2 = saveZone()
                                local state = calls.call("gui_yesno", screen, nil, nil, "clear label?")

                                if state then
                                    v.fs.setLabel(nil)
                                    draw()
                                else
                                    clear2()
                                    clear()
                                end
                            else
                                clear()
                            end
                        else
                            local screenshotY = 7
                            local strs, active =
                            {"  open", "----------------------", "  remove", "  rename", "  copy", "  cut"},
                            {true, false, not v.isAlias, not v.isAlias, not v.isAlias, not v.isAlias}

                            local isLine
                            local function addLine()
                                if not isLine then
                                    table.insert(strs, "----------------------")
                                    table.insert(active, false)
                                    isLine = true
                                    screenshotY = screenshotY + 1
                                end
                            end
                            if v.exp == "t2p" and not v.isDir then
                                addLine()

                                table.insert(strs, "  set as wallpaper")
                                table.insert(active, true)

                                screenshotY = screenshotY + 1
                            elseif devMode and v.exp == "app" and v.isDir then
                                addLine()

                                table.insert(strs, "  inside the package")
                                table.insert(active, true)

                                screenshotY = screenshotY + 1
                            elseif devMode and (v.exp == "lua" or v.exp == "plt") and not v.isDir then
                                addLine()

                                table.insert(strs, "  edit")
                                table.insert(active, true)

                                screenshotY = screenshotY + 1
                            end
                            if not v.isDir and
                                v.exp ~= "lua" and
                                v.exp ~= "t2p" and
                                v.exp ~= "dfpwm" and
                                v.exp ~= "mp3" and
                                v.exp ~= "wav" and
                                v.exp ~= "avi" and
                                v.exp ~= "mp4" and
                                v.exp ~= "plt" and
                                v.exp ~= "mid" and
                                v.exp ~= "midi" and
                                v.exp ~= "app" then
                                addLine()

                                table.insert(strs, "  open is text editor")
                                table.insert(active, true)

                                screenshotY = screenshotY + 1
                            end
                            --[[
                            if v.exp == "plt" and not v.isDir then
                                addLine()

                                table.insert(strs, "  set as theme")
                                table.insert(active, true)

                                screenshotY = screenshotY + 1
                            end
                            ]]

                            local posX, posY = window:toRealPos(windowEventData[3], windowEventData[4])

                            local clear = calls.call("screenshot", screen, posX, posY, 23, screenshotY)
                            local str, num = calls.call("gui_context", screen, posX, posY,
                            strs, active)

                            if num == 1 then
                                --clear()
                                fileDescriptor(v, nil, windowEventData[6])
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

                                if name then
                                    if #name ~= 0 and not name:find("%\\") and not name:find("%/") and
                                    (not name:find("%.") or devMode or not v.exp or v.exp == "") then --change expansion disabled
                                        local newexp = v.exp or ""
                                        if devMode then
                                            newexp = ""
                                        end
                                        local path = paths.concat(userPath, name .. "." .. newexp)
                                        if fs.exists(path) then
                                            warn("name exists")
                                            clear()
                                        else
                                            fs.rename(v.path, path)
                                            draw()
                                        end
                                    else
                                        warn("error in name")
                                        clear()
                                    end
                                else
                                    clear()
                                end
                            elseif num == 5 then
                                copyObject = v.path
                                isCut = false
                                clear()
                            elseif num == 6 then
                                copyObject = v.path
                                isCut = true
                                clear()
                            elseif str == "  set as wallpaper" then
                                fs.copy(v.path, "/data/wallpaper.t2p")
                                event.push("redrawDesktop")
                            elseif str == "  set as theme" then
                                calls.call("system_setTheme", v.path)
                                event.push("redrawDesktop")
                            elseif str == "  inside the package" then
                                fileDescriptor(v, true)
                            elseif str == "  edit" or str == "  open is text editor" then
                                execute("edit", v.path)
                                draw()
                            else
                                clear()
                            end
                        end
                        
                    end
                    break
                end
            end
        end
        --if not iconCliked and selectedIcons[userPath] then
            --selectedIcons[userPath] = nil
            --draw()
        --end
        if not iconCliked and windowEventData[5] == 1 then
            local posX, posY = window:toRealPos(windowEventData[3], windowEventData[4])

            if copyObject and not fs.exists(copyObject) then
                copyObject = nil
                isCut = false
            end
            
            local isRedraw
            local clear = calls.call("screenshot", screen, posX, posY, 33, 8)
            local str, num = calls.call("gui_context", screen, posX, posY,
            {"  back", "  paste", "--------------------------------", "  new image", "  new folder", "  new text file", "  download file from internet"},
            {true, not not copyObject, false, true, true, true, not not component.list("internet")()})
            if num == 1 then
                folderBack()
                isRedraw = true
            elseif num == 4 then --new image
                local clear = saveZone()
                local name = calls.call("gui_input", screen, nil, nil, "image name")
                clear()

                if type(name) == "string" then
                    local path = paths.concat(userPath, name .. ".t2p")
                    if not fs.exists(path) then
                        if #name == 0 or name:find("%.") or name:find("%/") or name:find("%\\") then
                            warn("error in name")
                        else
                            execute("paint", path)
                            draw()
                            isRedraw = true
                        end
                    else
                        warn("this name is occupied")
                    end
                end
            elseif num == 5 then --new folder
                local clear = saveZone()
                local name = calls.call("gui_input", screen, nil, nil, "folder name")
                clear()

                if type(name) == "string" then
                    local path = paths.concat(userPath, name)
                    if not fs.exists(path) then
                        if #name == 0 or (name:find("%.") and not devMode) or name:find("%/") or name:find("%\\") then
                            warn("error in name")
                        else
                            fs.makeDirectory(path)
                            draw()
                            isRedraw = true
                        end
                    else
                        warn("this name is occupied")
                    end
                end
            elseif num == 6 then --new text file
                local clear = saveZone()
                local name = calls.call("gui_input", screen, nil, nil, "text file name")
                clear()

                if type(name) == "string" then
                    local path = paths.concat(userPath, name .. (devMode and "" or ".txt"))
                    if not fs.exists(path) then
                        if #name == 0 or (name:find("%.") and not devMode) or name:find("%/") or name:find("%\\") then
                            warn("error in name")
                        else
                            execute("edit", path)
                            draw()
                            isRedraw = true
                        end
                    else
                        warn("this name is occupied")
                    end
                end
            elseif num == 2 then
                local copyFlag = true
                local toPath = paths.concat(userPath, paths.name(copyObject))
                if fs.exists(toPath) then
                    local clear = saveZone()
                    local replaseAllow = calls.call("gui_yesno", screen, nil, nil, "an object with this name is already present in this folder, should I replace it?")
                    if not replaseAllow then
                        clear()
                        copyFlag = false
                    end
                end

                if copyFlag then
                    if fs.exists(toPath) then
                        fs.remove(toPath)
                    end
                    fs.copy(copyObject, toPath)
                    
                    if isCut then
                        isCut = false
                        fs.remove(copyObject)
                    end
                    copyObject = nil
                    isCut = false
                    isRedraw = true
                    draw()
                end
            elseif num == 7 then
                local clear = saveZone()
                local url = gui_input(screen, nil, nil, "url")
                clear()
                if url then
                    local filename = url
                    local index = string.find(filename, "/[^/]*$")
                    if index then
                        filename = string.sub(filename, index + 1)
                    end
                    index = string.find(filename, "?", 1, true)
                    if index then
                        filename = string.sub(filename, 1, index - 1)
                    end

                    local path = paths.sconcat(userPath, filename)
                    if path then
                        local replaceAllow
                        if fs.exists(path) then
                            local clear = saveZone()
                            replaceAllow = calls.call("gui_yesno", screen, nil, nil, "an object with this name is already present in this folder, should I replace it?")
                            clear()
                        end
                        if not fs.exists(path) or replaceAllow then
                            local clear = saveZone()
                            gui_status(screen, nil, nil, "downloading file")
                            local data, err = getInternetFile(url)
                            clear()
                            if data then
                                local file, err = fs.open(path, "wb")
                                if file then
                                    file.write(data)
                                    file.close()
                                    isRedraw = true
                                    draw()
                                else
                                    warn("save error " .. (err or "unknown error"))
                                end
                            else
                                warn("download error " .. (err or "unknown error"))
                            end
                        end
                    else
                        warn("error in name")
                    end
                end
            end
            if not isRedraw then
                clear()
            end
        end
        ::bigSkip::
    end

    if eventData[1] == "key_down" then
        local ok
        for i, v in ipairs(component.invoke(screen, "getKeyboards")) do
            if eventData[2] == v then
                ok = true
            end
        end
        if ok then
            if eventData[4] == 200 then
                devModeCount = devModeCount + 1
            elseif eventData[4] == 208 then
                folderBack()
            elseif eventData[4] == 203 then
                listBack()
            elseif eventData[4] == 205 then
                listForward()
            end
        end
    end

    if computer.uptime() - devModeResetTime > 1 then
        devModeResetTime = computer.uptime()
        if devModeCount > 15 then
            if not devMode then
                computer.beep(2000)
            else
                computer.beep(1000)
            end
            setDevMode(not devMode)
            event.sleep(1)
        end
        devModeCount = 0
    end
end
