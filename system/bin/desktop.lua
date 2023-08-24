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

local colors = gui_container.colors

------------------------------------------------------------------------ settings

local knownExps = { --данные файлы не будет предложинно открыть в текстовом редакторе
    ["zip"] = true,
    ["rar"] = true,
    ["afpx"] = true,
    ["arch"] = true,
    ["dfpwm"] = true,
    ["mp3"] = true,
    ["wav"] = true,
    ["mid"] = true,
    ["midi"] = true,
    ["lua"] = true,
    ["app"] = true,
    ["t2p"] = true,
    ["plt"] = true,
    ["avi"] = true,
    ["mp4"] = true,
    ["dat"] = true,
    ["cfg"] = true,
    ["log"] = true,
    ["txt"] = true --текстовому документу не нужно отдельная кнопка, он по умалчанию открываеться через редактор
}

------------------------------------------------------------------------ init

local screen, isFirst = ...
local rx, ry = graphic.getResolution(screen)

local statusWindow = graphic.createWindow(screen, 1, 1, rx, 1)
local window = graphic.createWindow(screen, 1, 2, rx, ry - 1)

local wallpaperPath = "/data/wallpaper.t2p"
local userRootMain = "/data/userdata/"
local userPath = gui_container.userRoot
local iconsPath = gui_container.userRoot
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

fs.makeDirectory(gui_container.userRoot)
fs.makeDirectory(userPath)

local function isDev()
    return not not gui_container.devModeStates[screen]
end

local redrawFlag = true

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

local contextMenuOpen = false
local lockFlag = false

local function drawStatus()
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

    local power = constrain(math.ceil(map(computer.energy(), 0, computer.maxEnergy(), 0, 100) + 0.5), 0, 100)
    local str = "real time: " .. hours .. ":" .. minutes .. "   game time: " .. gameHours .. ":" .. gameMinutes .. "   " .. tostring(power) .. "%"

    statusWindow:fill(1, 1, rx, 1, colors.gray, 0, " ")
    statusWindow:set(window.sizeX - unicode.len(str), 1, colors.gray, colors.white, str)
    if not lockFlag then
        statusWindow:set(1, 1, contextMenuOpen and colors.blue or colors.lightGray, colors.white, " OS ")
    end
end

local function drawWallpaper()
    local function wdraw(path)
        local sx, sy = gui_readimagesize(path)
        local ix, iy = math.floor(((window.sizeX / 2) - (sx / 2)) + 0.5) + 1, math.floor(((window.sizeY / 2) - (sy / 2)) + 0.5) + 1
        ix, iy = window:toRealPos(ix, iy)
        pcall(calls.call, "gui_drawimage", screen, path, ix, iy)
    end

    window:clear(colors.lightBlue)

    local customPath = paths.concat(userPath, paths.name(wallpaperPath))
    if fs.exists(customPath) then
        wdraw(customPath)
    elseif fs.exists(wallpaperPath) then
        wdraw(wallpaperPath)
    end
end

local function isUninstallScript(icon)
    return fs.exists(paths.concat(icon.path, "uninstall.lua"))
end

local function isUninstallAvailable(icon)
    if icon.readonly then return false end
    if isDev() then return true end

    local data = "/data/"
    local vendor = "/vendor/"
    if icon.path:sub(1, #data) == data then --вы всегда можете удалить приложения из data
        return true
    elseif icon.path:sub(1, #vendor) == vendor then --вы можете удалить приложения вендора только если в нем есть uninstall.lua
        return isUninstallScript(icon)
    end
    return false
end

local function findIcon(name)
    local path = paths.concat("/data/icons", name .. ".t2p")
    if fs.exists(path) then
        return path
    end
    path = paths.concat("/system/icons", name .. ".t2p")
    if fs.exists(path) then
        return path
    end
end

local function draw(old, check) --вызывает все перерисовки
    checkData()
    local iconsCount = 0
    local tbl = fs.list(userPath)
    if not tbl then
        userPath = gui_container.userRoot
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
    if startIconsPoss[lUserPath] > iconsCount then
        startIconsPoss[lUserPath] = old or 1
    end
    if check and startIconsPoss[lUserPath] == (old or 1) then
        return
    end

    gui_status(screen, nil, nil, "loading file-list...")
    drawStatus()
    drawWallpaper()

    local str = "path: " .. paths.canonical(unicode.sub(userPath, unicode.len(gui_container.userRoot), unicode.len(userPath)))
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
        local readonly = fs.get(path).isReadOnly()
        local labelReadonly
        local isFs
        local fsd
        if fs.isDirectory(path) and fs.exists(paths.concat(path, "icon.t2p")) then
            icon = paths.concat(path, "icon.t2p")
        elseif exp and #exp > 0 and exp ~= "app" and exp ~= "t2p" then
            icon = findIcon(exp)
        elseif exp == "app" then
            icon = findIcon("app")
        elseif fs.isDirectory(path) then
            icon = findIcon("folder")

            for _, tbl in ipairs(fs.mountList) do
                if paths.canonical(path) .. "/" == tbl[2] then
                    isFs = true
                    fsd = tbl[1]
                    readonly = fsd.isReadOnly() --realonly диска и readonly на лейбели ПОЛНОСТЬЮ НЕЗАВИСИМЫЕ
                    labelReadonly = not pcall(fsd.setLabel, fsd.getLabel() or nil) --getLabel может вернуть no value, который отличаеться от nil в данном случаи
                    
                    local info = computer.getDeviceInfo()[fsd.address]
                    local clock = info and info.clock
                    local devtypepath = paths.concat(path, "external-data/devicetype.dat")
                    if fs.exists(devtypepath) then
                        local data = getFile(devtypepath)
                        if data then
                            icon = findIcon(data)
                        end
                    elseif fsd.address == computer.tmpAddress() then
                        icon = findIcon("tmp")
                    elseif clock == "20/20/20" then
                        if fsd.exists("/init.lua") then
                            icon = findIcon("bootdevice")
                        else
                            icon = findIcon("fdd")
                        end
                    else
                        icon = findIcon("hdd")
                    end
                    break
                end
            end
        elseif exp == "t2p" then
            icon = findIcon("t2p")
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
            icon = findIcon("unkownfile")
        end

        local name = preName
        if not name then
            if isDev() then
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

local function checkFolder()
    if unicode.sub(userPath, 1, unicode.len(gui_container.userRoot)) ~= gui_container.userRoot then
        userPath = gui_container.userRoot
    end
end

local function folderBack()
    local oldPath = userPath
    userPath = paths.path(userPath)
    checkFolder()
    if userPath ~= oldPath then
        draw()
    end
end

local timerEnable = true
event.timer(10, function()
    if not timerEnable then return end
    drawStatus()
end, math.huge)

local function warn(str)
    local clear = saveZone(screen)
    gui_warn(screen, nil, nil, str)
    clear()
end

local function execute(name, nickname, ...)
    timerEnable = false

    gui_status(screen, nil, nil, "loading...")
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

    local code, err = programs.load(path)
    if code then
        local ok, err = xpcall(code, debug.traceback, screen, nickname, ...)
        if not ok then
            gui_warn(screen, nil, nil, err or "unknown error")
        end
    else
        gui_warn(screen, nil, nil, err or "unknown error")
    end
    
    timerEnable = true
    redrawFlag = nil
    draw()
end

local function uninstallApp(path, nickname)
    local uninstallPath = paths.concat(path, "uninstall.lua")
    if fs.exists(uninstallPath) then
        execute(uninstallPath, nickname)
        return true
    else
        fs.remove(path)
    end
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
        elseif icon.exp == "lua" then
            execute("edit", nickname, icon.path)
            return true
        end
    end

    if icon.exp == "app" then
        if fs.isDirectory(icon.path) then
            execute(paths.concat(icon.path, "main.lua"), nickname)
        else
            execute(icon.path, nickname)
        end
        return true
    elseif fs.isDirectory(icon.path) then
        userPath = icon.path
        draw()
        return true
    elseif icon.exp == "t2p" then
        execute("paint", nickname, icon.path)
        return true
    elseif icon.exp == "lua" then
        execute(icon.path, nickname)
        return true
    elseif icon.exp == "plt" then
        local clear = saveZone(screen)
        local state = gui_yesno(screen, nil, nil, "apply this theme?")
        clear()

        if state then
            system_setTheme(icon.path)
            event.push("redrawDesktop")
        end
    elseif icon.exp == "txt" or icon.exp == "log" or icon.exp == "cfg" or (icon.exp == "dat" and isDev()) then
        execute("edit", nickname, icon.path, icon.exp == "log")
    elseif icon.exp == "mid" or icon.exp == "midi" then
        if programs.find("midi") then
            execute("midi", nickname, icon.path)
        else
            warn("please, download program \"midi\" from market")
        end
    elseif icon.exp == "dfpwm" then
        if programs.find("tape") then
            execute("tape", nickname, icon.path)
        else
            warn("please, download program \"tape\" from market")
        end
    elseif icon.exp == "afpx" then
        if programs.find("archiver") then
            execute("archiver", nickname, icon.path)
        else
            warn("please, download program \"archiver\" from market")
        end
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

local copyObject
local isCut = false

local function umountAll()
    local newtbl = {}
    for index, value in ipairs(fs.mountList) do
        newtbl[index] = value
    end

    for _, mountpoint in ipairs(newtbl) do
        if mountpoint[1].address ~= computer.tmpAddress() and mountpoint[1].address ~= fs.bootaddress then
            assert(fs.umount(mountpoint[2]))
        end
    end
end

local function mountAll()
    for address in component.list("filesystem") do
        if address ~= computer.tmpAddress() and address ~= fs.bootaddress then
            assert(fs.mount(address, fs.genName(address)))
        end
    end
end

local function doIcon(windowEventData)
    if windowEventData[1] == "touch" then
        if windowEventData[4] >= window.sizeY - 3 then
            if windowEventData[3] >= 1 and windowEventData[3] <= 2 then
                listBack()
                return
            elseif windowEventData[3] <= window.sizeX and windowEventData[3] >= window.sizeX - 1 then
                listForward()
                return
            elseif windowEventData[3] >= 3 and windowEventData[3] <= 4 then
                folderBack()
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
                        fileDescriptor(v, nil, windowEventData[6])
                    else
                        if v.isFs then
                            local screenshotY = 6
                            local strs, active =
                            {"  open", "  install os", "----------------------", "  set label", "  clear label"},
                            {true, not v.readonly, false, not v.labelReadonly, not v.labelReadonly}

                            --[[
                            local likeDisk = isLikeOsDisk(v.fs.address)
                            if likeDisk then
                                screenshotY = screenshotY + 1

                                table.insert(strs, 4, "  wipe data")
                                table.insert(active, 4, not v.readonly and v.fs.exists("/data"))
                            end
                            ]]

                            do
                                screenshotY = screenshotY + 1

                                table.insert(strs, 4, "  format")
                                table.insert(active, 4, not v.readonly)
                            end

                            if v.fs.exists("/init.lua") then
                                screenshotY = screenshotY + 2

                                table.insert(strs, "----------------------")
                                table.insert(active, false)

                                table.insert(strs, "  boot from this disk")
                                table.insert(active, true)
                            end

                            local posX, posY = window:toRealPos(windowEventData[3], windowEventData[4])

                            posX, posY = findPos(posX, posY, 23, screenshotY, rx, ry)
                            local clear = screenshot(screen, posX, posY, 23, screenshotY)
                            local str, num = gui_context(screen, posX, posY,
                            strs, active)
                            clear()

                            if num == 1 then
                                fileDescriptor(v, nil, windowEventData[6])
                            elseif str == "  install os" then
                                local success, err = sysclone(screen, posX, posY, v.fs)

                                if success ~= "cancel" then
                                    if success then
                                        umountAll()
                                        mountAll()
                                    elseif err then
                                        gui_warn(screen, nil, nil, err)
                                    end
                                    draw()
                                end
                            elseif str == "  format" then
                                local clear2 = saveZone(screen)
                                local state = gui_yesno(screen, nil, nil, "format?")
                                
                                if state then
                                    gui_status(screen, nil, nil, "formatting...")
                                    v.fs.remove("/")
                                    draw()
                                else
                                    clear2()
                                end
                                --[[
                            elseif str == "  wipe data" then
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
                                    umountAll()
                                    if not pcall(v.fs.setLabel, newlabel) then
                                        warn("invalid name")
                                    end
                                    mountAll()
                                    draw()
                                else
                                    clear2()
                                end
                            elseif str == "  clear label" then
                                local clear2 = saveZone(screen)
                                local state = gui_yesno(screen, nil, nil, "clear label?")

                                if state then
                                    umountAll()
                                    v.fs.setLabel(nil)
                                    mountAll()
                                    draw()
                                else
                                    clear2()
                                end
                            elseif str == "  boot from this disk" then
                                pcall(computer.setBootAddress, v.fs.address)
                                pcall(computer.setBootFile, "/init.lua")
                                pcall(computer.shutdown, "fast")
                            end
                        elseif v.isAlias then
                            local screenshotY = 4
                            local strs, active =
                            {"  open", "----------------------", "  uninstall"},
                            {true, false, isUninstallAvailable(v)}

                            local posX, posY = window:toRealPos(windowEventData[3], windowEventData[4])

                            posX, posY = findPos(posX, posY, 23, screenshotY, rx, ry)
                            local clear = screenshot(screen, posX, posY, 23, screenshotY)
                            local str, num = gui_context(screen, posX, posY, strs, active)
                            clear()

                            if num == 1 then
                                fileDescriptor(v, nil, windowEventData[6])
                            elseif num == 3 then
                                local clear = saveZone(screen)
                                local ok = gui_yesno(screen, nil, nil, "uninstall?")

                                if ok then
                                    if not uninstallApp(v.path, windowEventData[6]) then
                                        draw()
                                    end
                                else
                                    clear()
                                end
                            end
                        else
                            local screenshotY = 7
                            local strs, active =
                            {"  open", "----------------------"},
                            {true, false}

                            if v.exp == "app" then
                                table.insert(strs, "  uninstall")
                                table.insert(active, isUninstallAvailable(v))

                                if isDev() then
                                    table.insert(strs, "  rename")
                                    table.insert(active, not v.readonly)
                                end

                                table.insert(strs, "  copy")
                                table.insert(active, true)

                                table.insert(strs, "  cut")
                                table.insert(active, not v.readonly)
                            else
                                table.insert(strs, "  remove")
                                table.insert(active, not v.readonly)

                                table.insert(strs, "  rename")
                                table.insert(active, not v.readonly)

                                table.insert(strs, "  copy")
                                table.insert(active, true)

                                table.insert(strs, "  cut")
                                table.insert(active, not v.readonly)
                            end

                            local isLine
                            local function addLine()
                                if not isLine then
                                    table.insert(strs, "----------------------")
                                    table.insert(active, false)
                                    isLine = true
                                    screenshotY = screenshotY + 1
                                end
                            end
                            
                            if v.exp == "plt" and not v.isDir then
                                addLine()

                                table.insert(strs, "  set as theme")
                                table.insert(active, true)

                                screenshotY = screenshotY + 1
                            elseif v.exp == "t2p" and not v.isDir then
                                addLine()

                                table.insert(strs, "  set as wallpaper")
                                table.insert(active, true)

                                screenshotY = screenshotY + 1
                            elseif isDev() and v.exp == "app" and v.isDir then
                                addLine()

                                table.insert(strs, "  inside the package")
                                table.insert(active, true)

                                screenshotY = screenshotY + 1
                            end
                            
                            if isDev() and (v.exp == "lua" or v.exp == "plt") and not v.isDir then
                                addLine()

                                table.insert(strs, "  edit")
                                table.insert(active, true)

                                screenshotY = screenshotY + 1
                            elseif not v.isDir and not knownExps[v.exp] then
                                addLine()

                                table.insert(strs, "  open is text editor")
                                table.insert(active, true)

                                screenshotY = screenshotY + 1
                            end

                            isLine = false
                            for i, v2 in ipairs(gui_container.filesExps) do
                                if (not v2[1] or v2[1] == v.exp) and (v2[5] == nil or v2[5] == v.isDir) then
                                    addLine()

                                    table.insert(strs, "  " .. v2[3])
                                    table.insert(active, v2[4])

                                    screenshotY = screenshotY + 1
                                end
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

                            posX, posY = findPos(posX, posY, 23, screenshotY, rx, ry)
                            local clear = screenshot(screen, posX, posY, 23, screenshotY)
                            local str, num = gui_context(screen, posX, posY,
                            strs, active)
                            clear()

                            if str == "  open" then
                                fileDescriptor(v, nil, windowEventData[6])
                            elseif str == "  remove" then
                                local clear2 = saveZone(screen)
                                local state = gui_yesno(screen, nil, nil, "remove?")
                                clear2()
                                if state then
                                    fs.remove(v.path)
                                    draw()
                                end
                            elseif str == "  uninstall" then
                                local clear2 = saveZone(screen)
                                local state = gui_yesno(screen, nil, nil, "uninstall?")
                                clear2()
                                if state then
                                    if not uninstallApp(v.path, windowEventData[6]) then
                                        draw()
                                    end
                                end
                            elseif str == "  rename" then
                                local clear2 = saveZone(screen)
                                local fname = paths.name(v.path) or ""
                                if not isDev() then
                                    fname = paths.hideExtension(fname)
                                end
                                local name = gui_input(screen, nil, nil, "new name", nil, nil, fname)
                                clear2()

                                if name then
                                    if #name ~= 0 and not name:find("%\\") and not name:find("%/") and
                                    (not name:find("%.") or isDev() or not v.exp or v.exp == "") then --change expansion disabled
                                        local newexp = ""
                                        --if not isDev() then
                                        if not name:find("%.") then --даже если в devmode вы не поставите кастомное разширения, то оно перенесеться
                                            if v.exp and v.exp ~= "" then
                                                newexp = "." .. v.exp
                                            end
                                        end
                                        local path = paths.concat(userPath, name .. newexp)
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
                                fs.copy(v.path, "/data/wallpaper.t2p")
                                event.push("redrawDesktop")
                            elseif str == "  set as theme" then
                                system_setTheme(v.path)
                                event.push("redrawDesktop")
                            elseif str == "  inside the package" then
                                fileDescriptor(v, true)
                            elseif str == "  edit" or str == "  open is text editor" then
                                execute("edit", windowEventData[6], v.path, str == "  open is text editor" and not isDev())
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
            
            posX, posY = findPos(posX, posY, 33, 8, rx, ry)
            local clear = screenshot(screen, posX, posY, 33, 8)
            local str, num = gui_context(screen, posX, posY,
            {"  back", "  paste", "--------------------------------", "  new image", "  new folder", "  new text file", "  download file from internet"},
            {true, not not copyObject and not readonly, false, not readonly, not readonly, not readonly, not not component.list("internet")() and not readonly})
            clear()
            
            if num == 1 then
                folderBack()
            elseif num == 4 then --new image
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
            elseif num == 5 then --new folder
                local clear = saveZone(screen)
                local name = gui_input(screen, nil, nil, "folder name")
                clear()

                if type(name) == "string" then
                    local path = paths.concat(userPath, name)
                    if not fs.exists(path) then
                        if #name == 0 or (name:find("%.") and not isDev()) or name:find("%/") or name:find("%\\") then
                            warn("invalid name")
                        else
                            fs.makeDirectory(path)
                            draw()
                        end
                    else
                        warn("this name is occupied")
                    end
                end
            elseif num == 6 then --new text file
                local clear = saveZone(screen)
                local name = gui_input(screen, nil, nil, "text file name")
                clear()

                if type(name) == "string" then
                    local path = paths.concat(userPath, name .. (name:find("%.") and "" or ".txt"))
                    if not fs.exists(path) then
                        if #name == 0 or (name:find("%.") and not isDev()) or name:find("%/") or name:find("%\\") then
                            warn("invalid name")
                        else
                            execute("edit", windowEventData[6], path)
                        end
                    else
                        warn("this name is occupied")
                    end
                end
            elseif num == 2 then
                local copyFlag = true
                local toPath = paths.concat(userPath, paths.name(copyObject))
                if fs.exists(toPath) then
                    local clear = saveZone(screen)
                    local replaseAllow = gui_yesno(screen, nil, nil, "an object with this name is already present in this folder, should I replace it?")
                    if not replaseAllow then
                        clear()
                        copyFlag = false
                    end
                end

                if copyFlag then
                    if paths.canonical(toPath) ~= paths.canonical(copyObject) then
                        if fs.exists(toPath) then
                            fs.remove(toPath)
                        end
                        fs.copy(copyObject, toPath)
                        
                        if isCut then
                            fs.remove(copyObject)
                        end
                    end

                    copyObject = nil
                    isCut = false
                    draw()
                end
            elseif num == 7 then
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
                            replaceAllow = gui_yesno(screen, nil, nil, "an object with this name is already present in this folder, should I replace it?")
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
    lockFlag = true
    drawStatus()
    drawWallpaper()

    while true do
        local successful = gui_checkPassword(screen, nil, nil, not isFirst and firstLock)
        firstLock = nil

        if successful then
            break
        elseif successful == false then
            if isMultiscreen() then --нельзя выключить мультиманиторное устройтсво с заблокированого экрана, потому что один монитор может стоять на улице(знаю что редкий случай)
                gui_warn(screen, nil, nil, "you cannot turn off a multi-monitor device from a locked screen")
            else
                if gui_yesno(screen, nil, nil, "shutdown?") then
                    computer.shutdown()
                end
            end
        end
    end

    lockFlag = false
end

if registry.password then
    lock(true)
end

------------------------------------------------------------------------ main

local function setDev(state)
    if state == isDev() then return end
    --[[
    if state then
        gui_container.userRoot = "/"
    else
        gui_container.userRoot = userRootMain
    end
    ]]
    gui_container.devModeStates[screen] = state
    checkFolder()
    draw()
end

event.listen("redrawDesktop", function()
    redrawFlag = true
end)

event.listen("key_down", function(_, uuid, char, code)
    if isDev() then
        local ok
        for i, v in ipairs(component.invoke(screen, "getKeyboards")) do
            if v == uuid then
                ok = true
            end
        end
        if ok then
            if char == 0 and code == 46 then
                event.interruptFlag = screen
            end
        end
    end
end)

local devModeCount = 0
local devModeResetTime = 0

while true do
    if redrawFlag then
        redrawFlag = false
        draw()
    end

    local eventData = {computer.pullSignal(5)}
    local windowEventData = window:uploadEvent(eventData)
    local statusWindowEventData = statusWindow:uploadEvent(eventData)
    if statusWindowEventData[1] == "touch" then
        if statusWindowEventData[4] == 1 and statusWindowEventData[3] >= 1 and statusWindowEventData[3] <= 4 then
            contextMenuOpen = true
            drawStatus()
            local clear = screenshot(screen, 2, 2, 19, 7)
            local str, num = gui_context(screen, 2, 2,
            {"  about", "  settings", "  lock screen", "------------------", "  shutdown", "  reboot"},
            {true, true, not not registry.password, false, true, true})
            contextMenuOpen = false

            if num == 1 then
                execute("about", statusWindowEventData[6])
            elseif num == 2 then
                execute("settings", statusWindowEventData[6])
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

            drawStatus()
        end
    end

    doIcon(windowEventData)

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
            if not vendor.disableDevShortcut then
                if registry.soundEnable then
                    if not isDev() then
                        computer.beep(2000)
                    else
                        computer.beep(1000)
                    end
                end
                setDev(not isDev())
                event.sleep(1)
            else
                warn("dev-mode shortcut disabled by vendor")
            end
        end
        devModeCount = 0
    end
end
