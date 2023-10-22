--ВНИМАНИЯ, для кономии оперативной памяти, я загружаю данный файл один раз и создаю на него патоки
--соответственно таблица _ENV для всех desktop обшая, и тут нельзя использовать глобалы

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
local registry = require("registry")
local thread = require("thread")
local gui = require("gui")
local lastinfo = require("lastinfo")
local system = require("system")
local liked = require("liked")

local colors = gui_container.colors

------------------------------------------------------------------------ init

local screen, isFirst = ...
local rx, ry = graphic.getResolution(screen)

local statusWindow = graphic.createWindow(screen, 1, 1, rx, 1)
local window = graphic.createWindow(screen, 1, 2, rx, ry - 1)

------------------------------------------------------------------------ paths

local defaultUserPath = "/data/userdata/"
local wallpaperPath = "/data/wallpaper.t2p"
local userPath = gui_container.getUserRoot(screen)
local iconsPath = userPath
local iconAliases = {
    "/system/bin/about.app",
    "/system/bin/settings.app",
    "/system/bin/update.app",
    "/system/bin/market.app"
}
local userPaths = {
    "/vendor/bin",
    "/data/bin",
}

fs.makeDirectory(userPath)

------------------------------------------------------------------------ service

--[[
local function isDev()
    return not not gui_container.devModeStates[screen]
end
]]

local function isFileExps()
    return not not gui_container.viewFileExps[screen]
end

local redrawFlag = true
local desktopTh
local programTh

local listens = {}

local screenSaverDemo
local screenSaverScreenShot
local screenSaver
local screenSaverClosed
local lastScreenSaverTime = computer.uptime()

local devModeCount = 0
local devModeResetTime = 0

local copyObject
local isCut = false

local function runScreenSaver(path)
    if not screenSaverScreenShot then
        screenSaverScreenShot = screenshot(screen, 1, 1, rx, ry)
    end

    gui_container.isScreenSaver[screen] = true

    desktopTh:suspend()
    if programTh and not gui_container.noBlockOnScreenSaver[screen] then
        programTh:suspend()
    end

    if fs.exists(path) then
        local code, err = programs.load(path)
        if code then
            screenSaver = thread.create(code, screen)
            screenSaver:resume()
        else
            event.errLog("failed to load screen-saver: " .. (err or "unkown error"))
            screenSaverClosed = true
        end
    else
        screenSaverClosed = true
    end
end

------------------------------------------------------------------------ icons

local iconmode = 0
-- 0 - all
-- 1 - apps
-- 2 - files
-- 3 - disks

local iconsX = 3
local iconsY = 2
if rx == 160 and ry == 50 then
    iconsX = 9
    iconsY = 7
elseif rx == 80 and ry == 25 then
    iconsX = 5
    iconsY = 3
end

local iconSizeX = 8
local iconSizeY = 4

local startIconsPoss = {} --тут храниться страница выбраная на конкретном пути
--local selectedIcons = {}
local icons

local function checkData()
    if not startIconsPoss[paths.canonical(userPath)] then
        startIconsPoss[paths.canonical(userPath)] = 1
    end
end

------------------------------------------------------------------------ draw

local contextMenuOpen = nil
local lockFlag = false

local function drawStatus()
    --[[
    local timeZone = registry.timeZone or 0
    
    local hours, minutes, seconds = getRealTime(timeZone)
    hours = tostring(hours)
    minutes = tostring(minutes)
    if #hours == 1 then hours = "0" .. hours end
    if #minutes == 1 then minutes = "0" .. minutes end

    local gameHours, gameMinutes = getGameTime()
    gameHours = tostring(gameHours)
    gameMinutes = tostring(gameMinutes)
    if #gameHours == 1 then gameHours = "0" .. gameHours end
    if #gameMinutes == 1 then gameMinutes = "0" .. gameMinutes end

    local str = "real time: " .. hours .. ":" .. minutes .. "   game time: " .. gameHours .. ":" .. gameMinutes .. "   " .. tostring(system.getCharge()) .. "%"

    statusWindow:fill(1, 1, rx, 1, colors.gray, 0, " ")
    statusWindow:set(window.sizeX - unicode.len(str), 1, colors.gray, colors.white, str)
    ]]

    liked.drawUpBar(screen)
    if not lockFlag then
        statusWindow:set(1, 1, contextMenuOpen == 1 and colors.blue or colors.lightGray, colors.white, " OS ")
        statusWindow:set(6, 1, contextMenuOpen == 2 and colors.blue or colors.lightGray, colors.white, " FILES ")
    end
end

local function drawWallpaper()
    local baseColor = colors.lightBlue
    if registry.wallpaperBaseColor and colors[registry.wallpaperBaseColor] then
        baseColor = colors[registry.wallpaperBaseColor]
    end

    local function wdraw(path)
        local sx, sy = gui_readimagesize(path)
        if sx ~= rx or sy ~= ry then --на неполноэкранных обоях нужно сначала очистить экран
            window:clear(baseColor)
        end

        local ix, iy = math.round((window.sizeX / 2) - (sx / 2)) + 1, math.round((window.sizeY / 2) - (sy / 2)) + 1
        pcall(calls.call, "gui_drawimage", screen, path, ix, iy)
    end

    local customPath = paths.concat(userPath, paths.name(wallpaperPath))
    if fs.exists(customPath) then
        wdraw(customPath)
    elseif fs.exists(wallpaperPath) then
        wdraw(wallpaperPath)
    else
        window:clear(baseColor)
    end
end

local function isUninstallScript(icon)
    return fs.exists(paths.concat(icon.path, "uninstall.lua"))
end

local function isUninstallAvailable(icon)
    if icon.readonly then return false end
    --if isDev() then return true end

    local data = "/data/"
    local vendor = "/vendor/"
    if icon.path:sub(1, #data) == data then --вы всегда можете удалить приложения из data
        return true
    elseif icon.path:sub(1, #vendor) == vendor then --вы можете удалить приложения вендора только если в нем есть uninstall.lua
        return isUninstallScript(icon)
    end
    return false
end

local function drawBar(lUserPath, iconsCount)
    local curentPath = gui_container.toUserPath(screen, userPath)

    local currentPage = math.floor(startIconsPoss[lUserPath] // (iconsX * iconsY)) + 1
    local pageCount = math.floor((iconsCount - 1) // (iconsX * iconsY)) + 1

    if currentPage < 1 then currentPage = 1 end
    if pageCount < 1 then pageCount = 1 end

    --[[
    window:fill(1, window.sizeY - 1, rx, 1, colors.gray, 0, " ")
    if copyObject then
        window:set(2, window.sizeY - 1, colors.gray, colors.white, (isCut and "cutted: " or "copied: ") .. gui_container.short(copyObject, window.sizeX - 2))
    end
    ]]

    window:fill(1, window.sizeY, rx, 1, colors.gray, 0, " ")
    window:set(16, window.sizeY, colors.gray, colors.white, "path: " .. gui_container.short(curentPath, window.sizeX - 35))
    window:set(window.sizeX - 10, window.sizeY, colors.gray, colors.white, tostring(currentPage))
    window:set(window.sizeX - 8, window.sizeY, colors.gray, colors.white, "/")
    window:set(window.sizeX - 6, window.sizeY, colors.gray, colors.white, tostring(pageCount))

    --window:set(1, window.sizeY - 3, colors.lightGray, colors.white, " /")
    --window:set(1, window.sizeY - 2, colors.lightGray, colors.white, "/ ")
    --window:set(1, window.sizeY - 1, colors.lightGray, colors.white, "\\ ")
    --window:set(1, window.sizeY - 0, colors.lightGray, colors.white, " \\")

    --window:set(3, window.sizeY - 3, colors.red, colors.white, " /")
    --window:set(3, window.sizeY - 2, colors.red, colors.white, "/ ")
    --window:set(3, window.sizeY - 1, colors.red, colors.white, "\\ ")
    --window:set(3, window.sizeY - 0, colors.red, colors.white, " \\")
    window:set(1, window.sizeY, colors.red, colors.white, " << ")

    --window:set(window.sizeX - 3, window.sizeY - 3, colors.blue, colors.white, "RE")
    --window:set(window.sizeX - 3, window.sizeY - 2, colors.blue, colors.white, "FR")
    --window:set(window.sizeX - 3, window.sizeY - 1, colors.blue, colors.white, "ES")
    --window:set(window.sizeX - 3, window.sizeY - 0, colors.blue, colors.white, "H ")
    window:set(6, window.sizeY, colors.blue, colors.white, " @@ ")
    window:set(11, window.sizeY, colors.green, colors.white, "HOME")

    --window:set(window.sizeX - 1, window.sizeY - 3, colors.lightGray, colors.white, "\\ ")
    --window:set(window.sizeX - 1, window.sizeY - 2, colors.lightGray, colors.white, " \\")
    --window:set(window.sizeX - 1, window.sizeY - 1, colors.lightGray, colors.white, " /")
    --window:set(window.sizeX - 1, window.sizeY - 0, colors.lightGray, colors.white, "/ ")

    window:set(window.sizeX - 3, window.sizeY, colors.lightGray, colors.white, "<-")
    window:set(window.sizeX - 1, window.sizeY, colors.lightGray, colors.white, "->")
end

local function draw(old, check) --вызывает все перерисовки
    checkData()
    if not fs.exists(userPath) or not fs.isDirectory(userPath) then
        userPath = defaultUserPath
    end

    local iconsCount = 0
    local tbl = fs.list(userPath)
    if not tbl then
        userPath = gui_container.getUserRoot(screen)
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
        for i, path in ipairs(userPaths) do
            for i, file in ipairs(fs.list(path) or {}) do
                iconsCount = iconsCount + 1
            end
        end
    end
    local lUserPath = paths.canonical(userPath)
    if not startIconsPoss[lUserPath] or startIconsPoss[lUserPath] > iconsCount then
        startIconsPoss[lUserPath] = old or 1
    end
    if check and startIconsPoss[lUserPath] == (old or 1) then
        return
    end

    gui_status(screen, nil, nil, "loading file-list...")
    drawWallpaper()
    drawStatus()
    drawBar(lUserPath, iconsCount)

    icons = {}
    local count = 0

    local function addIcon(i, v, customPath)
        count = count + 1
        if count > (iconsX * iconsY) then
            return true
        end

        local path
        if customPath then
            path = customPath
        else
            path = paths.concat(userPath, v)
        end

        local exp = paths.extension(path)
        local fsProxy, localFsPath = fs.get(path)
        local isFs = paths.equals(localFsPath, "/")

        local shortName, fullName = liked.getName(screen, path)
        local icon = liked.getIcon(screen, path)

        local icondata = {
            shortName = shortName,
            fs = fsProxy,
            readonly = fs.isReadOnly(path),
            icon = icon,
            path = path,
            exp = exp,
            index = i,
            name = fullName,
            isAlias = not not customPath,
            isDir = fs.isDirectory(path)
        }

        if isFs then
            icondata.isFs = isFs
            icondata.labelReadonly = fs.isLabelReadOnly(path)
        end

        table.insert(icons, icondata)
    end

    local tbl = {}

    if paths.canonical(userPath) == paths.canonical(iconsPath) then
        for i, v in ipairs(iconAliases) do
            if fs.exists(v) then
                table.insert(tbl, {nil, v})
            end
        end
        for i, path in ipairs(userPaths) do
            for i, file in ipairs(fs.list(path) or {}) do
                table.insert(tbl, {nil, paths.concat(path, file)})
            end
        end
    end

    if iconmode == 0 or iconmode == 1 then
        for i, v in ipairs(fs.list(userPath)) do
            table.insert(tbl, {v})
        end
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
        for cx = -(iconsX // 2), (iconsX // 2) do
            count = count + 1
            local centerIconX = math.floor(((window.sizeX / 2) + (cx * 16) + 1) + 0.5)
            local centerIconY = math.floor(((window.sizeY / (iconsY + 1)) * cy) + 0.5) - 1
            if ry <= 16 and centerIconY >= 5 then
                centerIconY = centerIconY + 1
            end
            local iconX = math.floor((centerIconX - (iconSizeX / 2)) + 0.5)
            local iconY = math.floor((centerIconY - (iconSizeY / 2)) + 0.5)
            local icon = icons[count]
            
            if icon then
                icon.iconX = iconX
                icon.iconY = iconY

                --if selectedIcons[userPath] == icon.index then
                --    window:fill(iconX - 2, iconY - 1, iconSizeX + 4, iconSizeY + 2, colors.blue, 0, " ")
                --end
                local x, y = window:toRealPos(math.floor((centerIconX - (unicode.len(icon.shortName) / 2)) + 0.5), centerIconY + 2)
                gui_drawtext(screen, x, y, colors.white, icon.shortName)
                --window:set(iconX - (unicode.len(icon.name) // 2), iconY + iconY - 2, colors.lightBlue, colors.white, icon.name)
                if icon.icon then
                    local sx, sy = window:toRealPos(iconX, iconY)
                    pcall(gui_drawimage, screen, icon.icon, sx, sy, true)
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
    draw(old, true)
end

local function listBack()
    checkData()

    local lUserPath = paths.canonical(userPath)
    local old = startIconsPoss[lUserPath]
    startIconsPoss[lUserPath] = startIconsPoss[lUserPath] - (iconsX * iconsY)
    if startIconsPoss[lUserPath] < 1 then
        startIconsPoss[lUserPath] = 1
    end
    draw(old, true)
end

local function folderBack()
    local oldPath = userPath
    userPath = gui_container.checkPath(screen, paths.path(userPath))
    if userPath ~= oldPath then
        draw()
    end
end

local timerEnable = true
table.insert(listens, event.timer(5, function()
    if not timerEnable or screenSaver then return end
    drawStatus()
end, math.huge))

local function warn(str)
    local clear = saveZone(screen)
    gui_warn(screen, nil, nil, str or "unknown error")
    clear()
end

local function warnNoClear(str)
    gui_warn(screen, nil, nil, str or "unknown error")
end

--[[
local function appLoad(name, nickname)
    local path = programs.find(name)
    if not path or not fs.exists(path) or fs.isDirectory(path) then
        gui_warn(screen, nil, nil, "failed to launch application")
        draw()
        return
    end
    if fs.exists("/vendor/appChecker.lua") then
        local out = {programs.execute("/vendor/appChecker.lua", screen, nickname, path)}
        if not out[1] then
            gui_warn(screen, nil, nil, out[2])
            redrawFlag = nil
            draw()
            return
        elseif not out[2] then
            --gui_warn(screen, nil, nil, "you cannot run this application")
            redrawFlag = nil
            draw()
            return
        end
    end

    return programs.load(path)
end

local function getExecute(name, nickname, ...)
    local code, err = appLoad(name, nickname)

    if code then
        local result = {xpcall(code, debug.traceback, screen, nickname, ...)}
        if not result[1] then
            warn(result[2])
        end
        return result
    elseif err then
        warn(err)
    end
end
]]

local function execute(name, nickname, ...)
    timerEnable = false

    gui_status(screen, nil, nil, "loading...")
    
    local code, err = liked.loadApp(name, screen, nickname)
    if code then
        programTh = thread.createBackground(code, ...) --запуск программы в потоке чтобы созданые в ней потоки закрылись вместе с ней
        programTh:resume()
        local ok, err = true
        while true do
            if programTh:status() == "dead" then
                if not programTh.out[1] then --если ошибка произошла в функции которую возврашяет liked.loadApp (чего быть не должно)
                    ok, err = false, "osError: " .. (programTh.out[2] or "unknown error")
                elseif not programTh.out[2] then --если ошибка произошла в целевой программе
                    if programTh.out[3] then
                        ok, err = false, programTh.out[3]
                    end
                end
                break
            end
            event.yield()
        end
        programTh:kill()
        programTh = nil

        --local ok, err = xpcall(code, debug.traceback, screen, nickname, ...)
        if not ok then
            gui_warn(screen, nil, nil, err or "unknown error")
        end

        redrawFlag = nil
        draw()
    elseif err then
        gui_warn(screen, nil, nil, err)
        redrawFlag = nil
        draw()
    end
    
    timerEnable = true
end

local function uninstallApp(path, nickname)
    liked.uninstall(screen, nickname, path)
end

local function fileDescriptor(icon, alternative, nickname) --открывает файл, сам решает через какую программу это сделать
    --[[
    for i, v in ipairs(gui_container.filesExps) do
        if not v[1] or v[1] == icon.exp then
            execute(v[2], nickname, icon.path)
            return
        end
    end
    ]]

    if alternative then
        if fs.isDirectory(icon.path) then
            userPath = icon.path
            draw()
            return true
        elseif icon.exp == "lua" or icon.exp == "scrsv" then
            execute("edit", nickname, icon.path)
            return true
        end
    end

    if gui_container.openVia[icon.exp] then
        execute(gui_container.openVia[icon.exp], nickname, icon.path)
    elseif icon.exp == "app" then
        if fs.isDirectory(icon.path) then
            execute(paths.concat(icon.path, "main.lua"), nickname)
        else
            execute(icon.path, nickname)
        end
        return true
    elseif fs.isDirectory(icon.path) then
        userPath = gui_container.checkPath(screen, icon.path)
        draw()
        return true
    elseif icon.exp == "t2p" then
        execute("paint", nickname, icon.path)
        return true
    elseif icon.exp == "lua" then
        execute(icon.path, nickname)
        return true
    elseif icon.exp == "scrsv" then
        event.timer(0.1, function ()
            lastScreenSaverTime = computer.uptime()
            runScreenSaver(icon.path)
        end, 1)
    elseif icon.exp == "plt" then
        local clear = saveZone(screen)
        local state = gui_yesno(screen, nil, nil, "apply this palette?")
        clear()

        if state then
            system_setTheme(icon.path)
            event.push("redrawDesktop")
        end
    elseif icon.exp == "txt" or icon.exp == "log" or icon.exp == "cfg" or icon.exp == "dat" then
        execute("edit", nickname, icon.path, icon.exp == "log")
    else
        warn("file is not supported")
    end
end

--[[
local function addExp(name, exp)
    if not isDev() then
        return name .. "." .. exp
    else
        local realexp = paths.extension(name)
        if not realexp or realexp == "" then
            name = name .. "." .. exp
        end
        return name
    end
end
]]

local function runFunc(func, ...)
    local ok, err = pcall(func, ...)
    if not ok then
        warn(err)
    end
end

local function getActions(icon, nickname, strs, active, sep)
    local path = icon.path

    if fs.exists(path) and fs.isDirectory(path) then
        local actionPath = paths.concat(path, "actions.cfg") --раньше был lua, который выполнялся, но это слишком небезопастно
        if fs.exists(actionPath) and not fs.isDirectory(actionPath) then
            --local result = getExecute(actionPath, nickname) --unsafe

            local content = getFile(actionPath)
            if type(content) == "string" then
                local result = {pcall(unserialization, content)}
                event.yield() --предотващения краша при долгой десереализации

                if result and result[1] and type(result[2]) == "table" then
                    table.insert(strs, sep)
                    table.insert(active, false)

                    local funcs = {}
                    local count = 1
                    for _, value in ipairs(result[2]) do
                        if type(value) == "table" and type(value[1]) == "string" and type(value[3]) == "string" then
                            table.insert(strs, "  " .. value[1])
                            table.insert(active, not not value[2])
                            funcs[#strs] = function ()
                                execute(paths.xconcat(path, value[3]), nickname)
                            end
                            count = count + 1
                        end
                    end
                    if count == 1 then
                        table.remove(strs, #strs)
                        table.remove(active, #active)
                        return
                    end
                    return funcs, count
                end
            end
        end
    end
end

local function failCheck(ok, err)
    if not ok then
        warn(err)
        return false
    end
    return true
end

local function loadLicense(icon)
    if not icon.isDir then return end

    local licensePath = paths.concat(icon.path, "LICENSE")
    if not fs.exists(licensePath) then licensePath = paths.concat(icon.path, "license") end
    if not fs.exists(licensePath) then licensePath = paths.concat(icon.path, "LICENSE.txt") end
    if not fs.exists(licensePath) then licensePath = paths.concat(icon.path, "license.txt") end
    if not fs.exists(licensePath) then licensePath = paths.concat(icon.path, "LICENSE.md") end
    if not fs.exists(licensePath) then licensePath = paths.concat(icon.path, "license.md") end
    if not fs.exists(licensePath) then licensePath = nil end
    return licensePath
end

local function doIcon(windowEventData)
    if windowEventData[1] == "touch" then
        if windowEventData[4] >= window.sizeY then
            if windowEventData[3] >= 1 and windowEventData[3] <= 4 then
                folderBack()
                return
            elseif windowEventData[3] <= window.sizeX and windowEventData[3] >= window.sizeX - 1 then
                listForward()
                return
            elseif windowEventData[3] <= window.sizeX - 2 and windowEventData[3] >= window.sizeX - 3 then
                listBack()
                return
            elseif windowEventData[3] >= 6 and windowEventData[3] <= 9 then
                draw()
                return
            elseif windowEventData[3] >= 11 and windowEventData[3] <= 14 then
                local root = defaultUserPath
                if windowEventData[5] == 1 then
                    root = gui_container.getUserRoot(screen)
                end
                if not paths.equals(userPath, root) then
                    userPath = root
                    draw()
                end
                return
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
                        --if v.isFs and gui_container.isDiskLocked(v.fs.address) and not gui_container.isDiskAccess(v.fs.address) then
                        --    gui_container.getDiskAccess(screen, v.fs.address)
                        --else
                        fileDescriptor(v, nil, windowEventData[6])
                        --end
                    else
                        if v.isFs then
                            local strs, active =
                            {"  open", "  create dump", "  flash os", "  flash archive", true, "  format", "  set label", "  clear label"},
                            {true, true, not v.readonly, not v.readonly, false, not v.readonly, not v.labelReadonly, not v.labelReadonly}

                            --[[
                            local likeDisk = isLikeOsDisk(v.fs.address)
                            if likeDisk then
                                screenshotY = screenshotY + 1

                                table.insert(strs, 4, "  wipe data")
                                table.insert(active, 4, not v.readonly and v.fs.exists("/data"))
                            end
                            ]]

                            --[[
                            if v.devtype then
                                table.insert(strs, "  erase firmware")
                                table.insert(active, not v.readonly)

                                table.insert(strs, "  erase data")
                                table.insert(active, not v.readonly)

                                table.insert(strs, "  make a disk")
                                table.insert(active, not v.readonly)
                            else
                                table.insert(strs, "  format")
                                table.insert(active, not v.readonly)
                            end
                            ]]

                            if v.fs.exists("/init.lua") then
                                table.insert(strs, true)
                                table.insert(active, false)

                                table.insert(strs, "  boot from this disk")
                                table.insert(active, not registry.disableExternalBoot)
                            end

                            --[[
                            if gui_container.isDiskLocked(v.fs.address) and not gui_container.isDiskAccess(v.fs.address) then
                                for index, value in ipairs(active) do
                                    active[index] = false
                                end

                                table.insert(strs, 1, "  unlock")
                                table.insert(active, 1, true)
                            end
                            ]]

                            local posX, posY = window:toRealPos(windowEventData[3], windowEventData[4])

                            --posX, posY = findPos(posX, posY, 23, screenshotY, rx, ry)
                            local posX, posY, sizeX, sizeY = gui.contentPos(screen, posX, posY, strs)
                            local clear = screenshot(screen, posX, posY, sizeX + 2, sizeY + 1)
                            local str, num = gui.context(screen, posX, posY,
                            strs, active)
                            clear()

                            if str == "  open" then
                                fileDescriptor(v, nil, windowEventData[6])
                            elseif str == "  create dump" then
                                local archiver = require("archiver")
                                local clear = saveBigZone(screen)
                                local targetPath = gui_filepicker(screen, nil, nil, nil, archiver.supported[1], true)
                                
                                if targetPath then
                                    clear()
                                    gui_status(screen, nil, nil, "creating dump...")
                                    local ok, err = archiver.pack(v.path, targetPath)
                                    if not ok then
                                        warn(err)
                                    end
                                end
                                draw()
                            elseif str == "  flash os" then
                                local success, err = sysclone(screen, posX, posY, v.fs, v.name)

                                if success ~= "cancel" then
                                    if not success and err then
                                        gui_warn(screen, nil, nil, err)
                                    end
                                    draw()
                                end
                            --elseif str == "  unlock" then
                            --    gui_container.getDiskAccess(screen, v.fs.address)
                            elseif str == "  flash archive" then
                                local archiver = require("archiver")
                                local clear = saveBigZone(screen)
                                local archivePath = gui_filepicker(screen, nil, nil, nil, archiver.supported[1])
                                
                                if archivePath then
                                    clear()
                                    if gui_yesno(screen, nil, nil, "are you sure you want to flash the \"" .. gui.hideExtension(screen, archivePath) .. "\" archive to the \"" .. v.name .. "\"?") then
                                        gui_status(screen, nil, nil, "archive flashing...")
                                        local ok, err = archiver.unpack(archivePath, v.path)
                                        if not ok then
                                            warn(err)
                                        end
                                    end
                                end
                                draw()
                            elseif str == "  format" then
                                local clear2 = saveZone(screen)
                                local state = gui.pleaseType(screen, "FORMAT")
                                
                                if state then
                                    gui_status(screen, nil, nil, "formatting...")
                                    liked.assert(screen, v.fs.remove("/"))
                                    draw()
                                else
                                    clear2()
                                end
                            --[[
                            elseif str == "  make a disk" then
                                local clear2 = saveZone(screen)
                                local state = gui_yesno(screen, nil, nil, "wipe data?")
                                
                                if state then
                                    gui_status(screen, nil, nil, "wiping...")
                                    v.fs.remove("/data")
                                    draw()
                                else
                                    clear2()
                                end
                            elseif str == "  erase data" then
                                local clear2 = saveZone(screen)
                                local state = gui_yesno(screen, nil, nil, "wipe data?")
                                
                                if state then
                                    gui_status(screen, nil, nil, "wiping...")
                                    v.fs.remove("/data")
                                    draw()
                                else
                                    clear2()
                                end
                            ]]
                            elseif str == "  set label" then
                                local label = ""
                                local result = {pcall(v.fs.getLabel)}
                                if result[1] then
                                    label = result[2] or ""
                                end

                                local clear2 = saveZone(screen)
                                local newlabel = gui_input(screen, nil, nil, "new label", nil, nil, label)

                                if newlabel then
                                    liked.umountAll()
                                    if not pcall(v.fs.setLabel, newlabel) then
                                        warn("invalid name")
                                    end
                                    liked.mountAll()
                                    draw()
                                else
                                    clear2()
                                end
                            elseif str == "  clear label" then
                                local clear2 = saveZone(screen)
                                local state = gui_yesno(screen, nil, nil, "clear label on \"" .. (v.name or "disk") .. "\"?")

                                if state then
                                    liked.umountAll()
                                    v.fs.setLabel(nil)
                                    liked.mountAll()
                                    draw()
                                else
                                    clear2()
                                end
                            elseif str == "  boot from this disk" then
                                if not registry.disableExternalBoot then
                                    pcall(computer.setBootAddress, v.fs.address)
                                    pcall(computer.setBootFile, "/init.lua")
                                    pcall(computer.shutdown, "fast")
                                end
                            end
                        elseif v.isAlias then
                            local screenshotY = 4
                            local strs, active =
                            {"  open", true, "  uninstall"},
                            {true, false, isUninstallAvailable(v)}

                            local licensePath = loadLicense(v)
                            if licensePath then
                                table.insert(strs, 2, "  license")
                                table.insert(active, 2, true)
                                screenshotY = screenshotY + 1
                            end

                            local actions, count = getActions(v, windowEventData[6], strs, active, true)
                            if count then
                                screenshotY = screenshotY + count
                            end

                            local posX, posY = window:toRealPos(windowEventData[3], windowEventData[4])
                            --posX, posY = findPos(posX, posY, 23, screenshotY, rx, ry)
                            local posX, posY, sizeX, sizeY = gui.contentPos(screen, posX, posY, strs)
                            local clear = screenshot(screen, posX, posY, sizeX + 2, sizeY + 1)
                            local str, num = gui.context(screen, posX, posY, strs, active)
                            clear()

                            if str == "  open" then
                                fileDescriptor(v, nil, windowEventData[6])
                            elseif str == "  uninstall" then
                                local clear = saveZone(screen)
                                local ok = gui_yesno(screen, nil, nil, "uninstall \"" .. v.name .. "\"?")

                                if ok then
                                    if not uninstallApp(v.path, windowEventData[6]) then
                                        draw()
                                    end
                                else
                                    clear()
                                end
                            elseif str == "  license" then
                                execute("edit", windowEventData[6], licensePath, true)
                            elseif actions and actions[num] then
                                runFunc(actions[num])
                            end
                        else
                            local strs, active =
                            {"  open", true},
                            {true, false}

                            local licensePath = loadLicense(v)
                            if licensePath then
                                table.insert(strs, 2, "  license")
                                table.insert(active, 2, true)
                            end

                            if v.exp == "app" then
                                table.insert(strs, "  uninstall")
                                table.insert(active, isUninstallAvailable(v))
                            end
                            
                            table.insert(strs, "  remove")
                            table.insert(active, not v.readonly)

                            table.insert(strs, "  rename")
                            table.insert(active, not v.readonly)

                            table.insert(strs, "  copy")
                            table.insert(active, true)

                            table.insert(strs, "  cut")
                            table.insert(active, not v.readonly)

                            table.insert(strs, "  info")
                            table.insert(active, true)

                            if v.isDir then
                                table.insert(strs, "  pack to archive")
                                table.insert(active, true)
                            end

                            local isLine
                            local function addLine()
                                if not isLine then
                                    table.insert(strs, true)
                                    table.insert(active, false)
                                    isLine = true
                                end
                            end
                            
                            if v.exp == "plt" and not v.isDir then
                                addLine()

                                table.insert(strs, "  set as palette")
                                table.insert(active, true)
                            elseif v.exp == "t2p" and not v.isDir then
                                addLine()

                                table.insert(strs, "  set as wallpaper")
                                table.insert(active, true)
                            elseif v.exp == "scrsv" and not v.isDir then
                                addLine()

                                table.insert(strs, "  set as screensaver")
                                table.insert(active, true)
                            elseif v.exp == "app" then
                                addLine()

                                table.insert(active, true)
                                if v.isDir then
                                    table.insert(strs, "  inside the package")
                                else
                                    table.insert(strs, "  edit")
                                end
                            end
                            
                            if gui_container.editable[v.exp] and not v.isDir then
                                addLine()

                                table.insert(strs, "  edit")
                                table.insert(active, true)
                            elseif not v.isDir and not gui_container.knownExps[v.exp] then
                                addLine()

                                table.insert(strs, "  open is text editor")
                                table.insert(active, true)
                            end

                            isLine = false
                            for i, v2 in ipairs(gui_container.filesExps) do
                                if (not v2[1] or v2[1] == v.exp) and (v2[5] == nil or v2[5] == v.isDir) then
                                    addLine()

                                    table.insert(strs, "  " .. v2[3])
                                    table.insert(active, v2[4])
                                end
                            end
                            --[[
                            if v.exp == "plt" and not v.isDir then
                                addLine()

                                table.insert(strs, "  set as palette")
                                table.insert(active, true)

                                screenshotY = screenshotY + 1
                            end
                            ]]

                            local actions = getActions(v, windowEventData[6], strs, active, true)

                            local posX, posY = window:toRealPos(windowEventData[3], windowEventData[4])
                            --posX, posY = findPos(posX, posY, 23, #strs + 1, rx, ry)
                            local posX, posY, sizeX, sizeY = gui.contentPos(screen, posX, posY, strs)
                            local clear = screenshot(screen, posX, posY, sizeX + 2, sizeY + 1)
                            local str, num = gui.context(screen, posX, posY,
                            strs, active)
                            clear()

                            if str == "  open" then
                                fileDescriptor(v, nil, windowEventData[6])
                            elseif str == "  info" then
                                execute("fileinfo", windowEventData[6], v.path)
                            elseif str == "  pack to archive" then
                                local packFolder = v.path
                                local clear = saveBigZone(screen)
                                local outPath = gui_filepicker(screen, nil, nil, nil, "afpx", true)
                                clear()

                                if outPath then
                                    local archiver = require("archiver")
                                    gui_status(screen, nil, nil, "packaging \"" .. gui_container.toUserPath(screen, packFolder) .. "\" to \"" .. gui_container.toUserPath(screen, outPath) .. "\"")
                                    liked.assertNoClear(screen, archiver.pack(packFolder, outPath))
                                    draw()
                                end
                            elseif str == "  remove" then
                                local clear2 = saveZone(screen)
                                local state = gui_yesno(screen, nil, nil, "remove \"" .. v.name .. "\"?")
                                clear2()
                                if state then
                                    liked.assert(screen, fs.remove(v.path))
                                    draw()
                                end
                            elseif str == "  uninstall" then
                                local clear2 = saveZone(screen)
                                local state = gui_yesno(screen, nil, nil, "uninstall \"" .. v.name .. "\"?")
                                clear2()
                                if state then
                                    if not uninstallApp(v.path, windowEventData[6]) then
                                        draw()
                                    end
                                end
                            elseif str == "  rename" then
                                local clear2 = saveZone(screen)
                                local fname = paths.name(v.path) or ""
                                if not isFileExps() then
                                    fname = paths.hideExtension(fname)
                                end
                                local name = gui_input(screen, nil, nil, "new name", nil, nil, fname)
                                clear2()

                                if name then
                                    if #name ~= 0 and not name:find("%\\") and not name:find("%/") then
                                        --с показаными разширениями вы можете стереть разширения с файла, без этого разширения будет переноситься с старого имени
                                        if not isFileExps() and not name:find("%.") and v.exp and v.exp ~= "" then
                                            name = name .. "." .. v.exp
                                        end

                                        local path = paths.concat(userPath, name)
                                        if fs.exists(path) then
                                            warn("name exists")
                                        else
                                            fs.rename(v.path, path)
                                            draw()
                                        end
                                    else
                                        warn("invalid name")
                                    end
                                end
                            elseif str == "  copy" then
                                copyObject = v.path
                                isCut = false
                            elseif str == "  cut" then
                                copyObject = v.path
                                isCut = true
                            elseif str == "  set as wallpaper" then
                                failCheck(fs.copy(v.path, wallpaperPath))
                                event.push("redrawDesktop")
                            elseif str == "  set as screensaver" then
                                failCheck(fs.copy(v.path, gui_container.screenSaverPath))
                            elseif str == "  set as palette" then
                                system_setTheme(v.path)
                                event.push("redrawDesktop")
                            elseif str == "  inside the package" then
                                fileDescriptor(v, true)
                            elseif str == "  edit" or str == "  open is text editor" then
                                --execute("edit", windowEventData[6], v.path, str == "  open is text editor" and not isDev())
                                execute("edit", windowEventData[6], v.path)
                            elseif str == "  license" then
                                execute("edit", windowEventData[6], licensePath, true)
                            elseif actions and actions[num] then
                                runFunc(actions[num])
                            else
                                for i, v2 in ipairs(gui_container.filesExps) do
                                    if "  " .. v2[3] == str then
                                        execute(v2[2], windowEventData[6], v.path .. (v2[6] or ""))
                                        break
                                    end
                                end
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
            local readonly = fs.get(userPath).isReadOnly()
            
            local strs = {"  paste", "  download file", true, "  new directory", "  new text-file", "  new image"}
            local actives = {not not copyObject and not readonly,   not not component.list("internet")() and not readonly,   false,   not readonly,   not readonly,   not readonly}

            local creaters = {}
            local creatersI = #strs + 1
            for _, obj in ipairs(gui_container.newCreate) do
                local name, exp, check, create = table.unpack(obj)
                if type(name) == "string" and type(exp) == "string" and type(check) == "function" and type(create) == "function" then
                    table.insert(strs, "  new " .. obj[1])
                    
                    local allowCreate = false
                    local result = {pcall(check)}
                    if not result[1] then
                        warn(result[2])
                    else
                        allowCreate = not not result[2]
                    end

                    table.insert(actives, allowCreate)

                    creaters[creatersI] = {name, exp, create}
                    creatersI = creatersI + 1
                end
            end

            local posX, posY, sizeX, sizeY = gui.contentPos(screen, posX, posY, strs)
            local clear = screenshot(screen, posX, posY, sizeX + 2, sizeY + 1)
            local str, num = gui.context(screen, posX, posY, strs, actives)
            clear()
            
            if str == "  new image" then --new image
                local clear = saveZone(screen)
                local name = gui_input(screen, nil, nil, "image name")
                clear()

                if type(name) == "string" then
                    local path = paths.concat(userPath, name .. ".t2p")
                    if not fs.exists(path) then
                        if #name == 0 or name:find("%.") or name:find("%/") or name:find("%\\") then
                            warn("invalid name")
                        else
                            execute("paint", windowEventData[6], path)
                        end
                    else
                        warn("this name is occupied")
                    end
                end
            elseif str == "  new directory" then --new directory
                local clear = saveZone(screen)
                local name = gui_input(screen, nil, nil, "directory name")
                clear()

                if type(name) == "string" then
                    local path = paths.concat(userPath, name)
                    if not fs.exists(path) then
                        if #name == 0 or name:find("%/") or name:find("%\\") then
                            warn("invalid name")
                        else
                            liked.assertNoClear(screen, fs.makeDirectory(path))
                            draw()
                        end
                    else
                        warn("this name is occupied")
                    end
                end
            elseif str == "  new text-file" then --new text-file
                local clear = saveZone(screen)
                local name = gui_input(screen, nil, nil, "text-file name")
                clear()

                if type(name) == "string" then
                    local path = paths.concat(userPath, name .. (name:find("%.") and "" or ".txt"))
                    if not fs.exists(path) then
                        if #name == 0 or name:find("%/") or name:find("%\\") then
                            warn("invalid name")
                        else
                            execute("edit", windowEventData[6], path)
                        end
                    else
                        warn("this name is occupied")
                    end
                end
            elseif str == "  paste" then
                local copyFlag = true --произойдет ли копирования

                
                local toPath = paths.concat(userPath, paths.name(copyObject))
                local oneDir = paths.path(copyObject) == paths.path(toPath) --если копирования и вставка производиться из одной и той же директории

                if oneDir and fs.exists(toPath) then
                    local name = paths.name(copyObject)
                    local exp = paths.extension(name)
                    if exp then
                        name = paths.hideExtension(name)
                    end

                    for i = 1, math.huge do
                        toPath = paths.concat(userPath, name .. "_" .. tostring(i) .. (exp and ("." .. exp) or ""))
                        if not fs.exists(toPath) then break end
                    end
                end
                
                local isDir = fs.isDirectory(copyObject)
                if fs.exists(toPath) then
                    if isDir ~= fs.isDirectory(toPath) then
                        warn("name is occupied")
                        copyFlag = false
                    else
                        local clear = saveZone(screen)
                        local replaseAllow = gui_yesno(screen, nil, nil, isDir and "merge directories?" or "overwrite the file?")
                        if not replaseAllow then
                            clear()
                            copyFlag = false
                        end
                    end
                end

                if copyFlag then
                    if paths.canonical(toPath) ~= paths.canonical(copyObject) then
                        local tname = isDir and "directory" or "file"
                        gui_status(screen, nil, nil, isCut and ("moving the " .. tname .. "...") or ("copying the " .. tname .. "..."))
                        if failCheck(fs.copy(copyObject, toPath)) and isCut then
                            liked.assert(screen, fs.remove(copyObject))
                        end
                    end

                    copyObject = nil
                    isCut = false
                    draw()
                end
            elseif str == "  download file" then
                local clear = saveZone(screen)
                local url = gui_input(screen, nil, nil, "url")
                clear()
                if url and url ~= "" then
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
                            local clear = saveZone(screen)
                            replaceAllow = gui_yesno(screen, nil, nil, "overwrite the file?")
                            clear()
                        end
                        if not fs.exists(path) or replaceAllow then
                            local clear = saveZone(screen)
                            gui_status(screen, nil, nil, "downloading file...")
                            local data, err = getInternetFile(url)
                            clear()
                            if data then
                                local file, err = fs.open(path, "wb")
                                if file then
                                    file.write(data)
                                    file.close()
                                    draw()
                                else
                                    warn("save error " .. (err or "unknown error"))
                                end
                            else
                                warn("download error " .. (err or "unknown error"))
                            end
                        end
                    else
                        warn("invalid name")
                    end
                end
            elseif creaters[num] then
                local clear = saveZone(screen)
                local name = gui_input(screen, nil, nil, creaters[num][1] .. " name")
                clear()

                if type(name) == "string" then
                    local path = paths.concat(userPath, name .. (name:find("%.") and "" or ("." .. creaters[num][2])))
                    if not fs.exists(path) then
                        if #name == 0 or name:find("%/") or name:find("%\\") then
                            warn("invalid name")
                        else
                            gui_status(screen, nil, nil, "creating a " .. creaters[num][1] .. "...")
                            local result = {pcall(creaters[num][3], path)}
                            if not result[1] then
                                warnNoClear(result[2])
                            else
                                if not result[2] then
                                    warnNoClear(result[3])
                                end
                            end
                            draw()
                        end
                    else
                        warn("this name is occupied")
                    end
                end
            end
        end
    end
end

------------------------------------------------------------------------ lock screen

local function isMultiscreen()
    local count = 0
    for address in component.list("screen") do
        if count >= 1 then
            return true
        end
        count = count + 1
    end
end

local function lock(firstLock)
    if not registry.password then return end

    lockFlag = true
    drawWallpaper()
    drawStatus()

    local th
    th = thread.create(function ()
        while true do
            local successful = gui_checkPassword(screen, nil, nil, not isFirst and firstLock)
            firstLock = nil

            if successful then
                th:kill()
                th = nil
                break
            elseif successful == false then
                if isMultiscreen() then --нельзя выключить мультиманиторное устройтсво с заблокированого экрана, потому что один монитор может стоять на улице(знаю что редкий случай)
                    local clear = saveZone(screen)
                    gui_warn(screen, nil, nil, "you cannot turn off a multi-monitor device from a locked screen")
                    clear()
                else
                    local clear = saveZone(screen)
                    if gui_yesno(screen, nil, nil, "shutdown?") then
                        computer.shutdown()
                    end
                    clear()
                end
            end
        end
    end)
    th:resume()

    while th do
        if screenSaver then --при активации screenSaver lock вылетает, но при деактивации он снова включиться
            th:kill()
            lockFlag = false
            return true
        end
        event.yield()
    end

    lockFlag = false
end

------------------------------------------------------------------------ screensaver & interrupt

local function updateScreenSaver()
    lastScreenSaverTime = computer.uptime()

    if not screenSaver then return end
    screenSaver:kill()
    screenSaver = nil

    screenSaverClosed = true
end

table.insert(listens, event.listen(nil, function (eventName, uuid)
    if uuid == screen and (eventName == "touch" or eventName == "drag" or eventName == "scroll") then
        updateScreenSaver()
    end
end))

table.insert(listens, event.listen("key_down", function(_, uuid, char, code)
    local ok
    for i, v in ipairs(lastinfo.keyboards[screen]) do
        if v == uuid then
            ok = true
        end
    end

    if ok then
        if char == 0 and code == 46 and not lockFlag and not screenSaver and not gui_container.noInterrupt[screen] then
            event.interruptFlag = programTh
        end

        updateScreenSaver()
    end
end))

local function checkScreenSaver()
    if gui_container.noScreenSaver[screen] then
        lastScreenSaverTime = computer.uptime()
    end

    if not screenSaver and (screenSaverDemo == screen or screenSaverDemo == true or (registry.screenSaverTimer and computer.uptime() - lastScreenSaverTime > registry.screenSaverTimer)) then
        lastScreenSaverTime = computer.uptime()

        if not gui_container.noScreenSaver[screen] then
            runScreenSaver(gui_container.screenSaverPath)
        end
    end
    screenSaverDemo = nil
end

table.insert(listens, event.timer(1, function ()
    checkScreenSaver()
end, math.huge))

table.insert(listens, event.listen("screenSaverDemo", function(_, screen)
    screenSaverDemo = screen
    checkScreenSaver()
end))

thread.create(function ()
    while true do
        if screenSaverClosed then
            if not lock() then
                screenSaverScreenShot()
                screenSaverScreenShot = nil

                gui_container.isScreenSaver[screen] = nil

                desktopTh:resume()
                if programTh and not gui_container.noBlockOnScreenSaver[screen] then
                    programTh:resume()
                end
            end

            screenSaverClosed = nil
        end

        event.yield()
    end
end):resume()

------------------------------------------------------------------------ desktop

table.insert(listens, event.listen("redrawDesktop", function()
    redrawFlag = true
end))

desktopTh = thread.create(function ()
    local warnPrinted

    while true do
        if redrawFlag then
            redrawFlag = false
            draw()
            if not warnPrinted then
                local clear = saveZone(screen)
                if computer.totalMemory() / 1024 < 512 then
                    gui_warn(screen, nil, nil, "small amount of RAM on the device\nthis can lead to problems")
                end
                local rootfs = fs.get("/")
                if (rootfs.spaceTotal() - rootfs.spaceUsed()) / 1024 < 128 then
                    gui_warn(screen, nil, nil, "not enough free disk space\nthis can lead to problems")
                end
                clear()

                warnPrinted = true
            end
        end

        local eventData = {computer.pullSignal(0.5)}
        local windowEventData = window:uploadEvent(eventData)
        local statusWindowEventData = statusWindow:uploadEvent(eventData)
        if statusWindowEventData[1] == "touch" then
            if statusWindowEventData[4] == 1 and statusWindowEventData[3] >= 1 and statusWindowEventData[3] <= 4 then
                contextMenuOpen = 1
                drawStatus()
                local clear = screenshot(screen, 2, 2, 28, 7 + 4)
                local str, num = gui.context(screen, 2, 2,
                {"  lock screen", true, "  about", "  settings", "  market", true, "  shutdown", "  reboot"},
                {not not registry.password, false, true, true, true, false, not not computer.shutdown, not not computer.shutdown})
                contextMenuOpen = nil

                if str == "  about" then
                    execute("about", statusWindowEventData[6])
                elseif str == "  settings" then
                    execute("settings", statusWindowEventData[6])
                elseif str == "  market" then
                    execute("market", statusWindowEventData[6])
                elseif str == "  lock screen" then
                    clear()
                    drawStatus()

                    gui_container.isScreenSaver[screen] = true --ручная блокировка работает как screenSaver по этому устанавливаем флаг

                    screenSaverScreenShot = screenshot(screen, 1, 1, rx, ry)
                    screenSaverClosed = true
                    desktopTh:suspend()
                    if programTh and not gui_container.noBlockOnScreenSaver[screen] then
                        programTh:suspend()
                    end
                    event.yield()
                elseif str == "  shutdown" then
                    computer.shutdown()
                elseif str == "  reboot" then
                    computer.shutdown(true)
                else
                    clear()
                end
                
                drawStatus()
            elseif statusWindowEventData[4] == 1 and statusWindowEventData[3] >= 6 and statusWindowEventData[3] <= 12 then
                contextMenuOpen = 2
                drawStatus()
                local clear = screenshot(screen, 7, 2, 28, 3)
                local str, num = gui.context(screen, 7, 2,
                {gui_container.viewFileExps[screen] and "  hide file extensions  " or "  show file extensions  ", gui_container.userRoot[screen] and "  hide root directory" or "  show root directory"},
                {not registry.disableFileExps, not registry.disableRootAccess})
                contextMenuOpen = nil

                if num == 1 then
                    gui_container.viewFileExps[screen] = not gui_container.viewFileExps[screen]
                    draw()
                elseif num == 2 then
                    if gui_container.userRoot[screen] then
                        gui_container.userRoot[screen] = nil
                    else
                        gui_container.userRoot[screen] = "/"
                    end
                    userPath = gui_container.checkPath(screen, userPath)
                    draw()
                else
                    clear()
                end
                
                drawStatus()
            end
        end

        doIcon(windowEventData)

        if eventData[1] == "key_down" then
            local ok
            for i, v in ipairs(lastinfo.keyboards[screen]) do
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
    end
end)

if not lock(true) then
    desktopTh:resume()
end

local selfTh = thread.current()
function selfTh:kill()
    if desktopTh then
        desktopTh:kill()
    end
    if programTh then
        programTh:kill()
    end
    for _, listen in ipairs(listens) do
        event.cancel(listen)
    end
    selfTh:raw_kill()
end
event.wait()