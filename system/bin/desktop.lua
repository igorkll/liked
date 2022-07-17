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

local colors = gui_container.colors

------------------------------------

local screen = ...
local rx, ry = graphic.findGpu(screen).getResolution()

local statusWindow = graphic.classWindow:new(screen, 1, 1, rx, 1)
local window = graphic.classWindow:new(screen, 1, 2, rx, ry - 1)

local wallpaperPath = "/data/wallpaper.t2p"
--[[
local userRoot = "/data/userdata/"
local userPath = userRoot
]]
local userRootMain = "/data/userdata/"
local userRoot = userRootMain
local userPath = userRootMain
local iconsPath = userRootMain
local iconAliases = {"/system/bin/settings.app", "/system/bin/update.app"}

fs.makeDirectory(userRoot)
fs.makeDirectory(userPath)

------------------------------------

local iconsX = 4
local iconsY = 2

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
    if not startIconsPoss[userPath] then
        startIconsPoss[userPath] = 1
    end
end

local function drawStatus()
    local timeZone = 3
    local timeZonePath = "/data/timeZone.dat"
    if fs.exists(timeZonePath) then
        local file = fs.open(timeZonePath, "rb")
        local data = tonumber(file.readAll())
        file.close()
        if data then
            timeZone = data
        end
    end
    local hours, minutes, seconds = calls.call("getRealTime", timeZone)
    hours = tostring(hours)
    minutes = tostring(minutes)
    if #hours == 1 then hours = "0" .. hours end
    if #minutes == 1 then minutes = "0" .. minutes end
    local str = hours .. ":" .. minutes

    statusWindow:fill(1, 1, rx, 1, colors.gray, 0, " ")
    statusWindow:set(window.sizeX - unicode.len(str), 1, colors.gray, colors.white, str)
    statusWindow:set(1, 1, colors.lightGray, colors.white, " OS ")

    local str = tostring(math.floor(calls.call("map", computer.energy(), 0, computer.maxEnergy(), 0, 100) + 0.5)) .. "%"
    statusWindow:set(window.sizeX - 7 - unicode.len(str), 1, colors.gray, colors.white, str)
end

local function draw(old)
    redrawFlag = false
    checkData()

    drawStatus()
    window:clear(colors.lightBlue)

    local str = "path: " .. unicode.sub(userPath, unicode.len(userRoot), unicode.len(userPath))
    window:set(math.floor(((window.sizeX / 2) - (unicode.len(str) / 2)) + 0.5),
    window.sizeY, colors.lightGray, colors.gray, str)

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
        pcall(calls.call, "gui_drawimage", screen, wallpaperPath, ix, iy)
    end

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
    end

    if startIconsPoss[userPath] > iconsCount then
        startIconsPoss[userPath] = old or 1
    end

    local str = tostring(math.floor(startIconsPoss[userPath] // (iconsX * iconsY)) + 1) .. "/" ..
    tostring(math.floor((iconsCount - 1) // (iconsX * iconsY)) + 1)
    window:set(math.floor(((window.sizeX / 2) - (unicode.len(str) / 2)) + 0.5), window.sizeY - 1, colors.lightGray, colors.gray, str)

    icons = {}
    local count = 0

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
        if fs.isDirectory(path) and fs.exists(paths.concat(path, "icon.t2p")) then
            icon = paths.concat(path, "icon.t2p")
        elseif exp and #exp > 0 and exp ~= "app" and exp ~= "t2p" then
            icon = paths.concat("/system/icons", exp .. ".t2p")
        elseif exp == "app" then
            icon = "/system/icons/app.t2p"
        elseif exp == "t2p" then
            icon = "/system/icons/t2p.t2p"
            local iconPath
            if fs.isDirectory(path) then
                if fs.exists(paths.concat(path, "icon.t2p")) then
                    iconPath = paths.concat(path, "icon.t2p")
                end
            else
                iconPath = path
            end

            if iconPath then
                local ok, sx, sy = pcall(calls.call, "gui_readimagesize", iconPath)
                if ok and sx == 8 and sy == 4 then
                    icon = iconPath
                end
            end
        elseif fs.isDirectory(path) then
            icon = "/system/icons/folder.t2p"

            for _, tbl in ipairs(fs.mountList) do
                if paths.canonical(path) .. "/" == tbl[2] then
                    local info = computer.getDeviceInfo()[tbl[1].address]
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
                        preName = (component.invoke(tbl[1].address, "getLabel") or data) .. "-" .. tbl[1].address:sub(1, 5)
                    elseif tbl[1].address == computer.tmpAddress() then
                        icon = "/system/icons/tmp.t2p"
                    elseif clock == "20/20/20" then
                        icon = "/system/icons/fdd.t2p"
                    else
                        icon = "/system/icons/hdd.t2p"
                    end
                    break
                end
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
        table.insert(icons, {icon = icon, path = path, exp = exp, index = i, name = name, isAlias = not not customPath, isDir = fs.isDirectory(path)})
    end

    local tbl = {}

    if paths.canonical(userPath) == paths.canonical(iconsPath) then
        for i, v in ipairs(iconAliases) do
            if fs.exists(v) then
                table.insert(tbl, {nil, v})
            end
        end
    end

    for i, v in ipairs(fs.list(userPath)) do
        table.insert(tbl, {v})
    end

    for i, v in ipairs(tbl) do
        if i >= startIconsPoss[userPath] and i <= iconsCount then
            if addIcon(i, v[1], v[2]) then
                break
            end
        end
    end

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

local function fileDescriptor(icon, alternative)
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
            execute(paths.concat(icon.path, "main.lua"))
        else
            execute(icon.path)
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
        execute(icon.path)
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
    elseif icon.exp == "txt" then
        execute("edit", icon.path)
        draw()
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

function execute(name, ...) --эта функция доступна толко в desktop хотя и обьявленна как глобальныя
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

while true do
    if redrawFlag then
        draw()
    end
    local eventData = {computer.pullSignal(0.5)}
    local windowEventData = window:uploadEvent(eventData)
    local statusWindowEventData = statusWindow:uploadEvent(eventData)
    if statusWindowEventData[1] == "touch" then
        if statusWindowEventData[4] == 1 and statusWindowEventData[3] >= 1 and statusWindowEventData[3] <= 4 then
            local clear = calls.call("screenshot", screen, 2, 2, 19, 6)
            local str, num = calls.call("gui_context", screen, 2, 2,
            {"  about", "  settings", "------------------", "  shutdown", "  reboot"},
            {true, true, false, true, true})
            if num == 1 then
                execute("about")
                draw()
            elseif num == 2 then
                execute("settings")
                draw()
            elseif num == 4 then
                computer.shutdown()
            elseif num == 5 then
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
                        fileDescriptor(v)
                    else
                        local screenshotY = 7
                        local strs, active =
                        {"  open", "----------------------", "  remove", "  rename", "  copy", "  cut"},
                        {true, false, not v.isAlias, not v.isAlias, not v.isAlias, not v.isAlias}

                        if v.exp == "t2p" and not v.isDir then
                            table.insert(strs, "----------------------")
                            table.insert(active, false)

                            table.insert(strs, "  set as wallpaper")
                            table.insert(active, true)

                            screenshotY = screenshotY + 2
                        elseif v.exp == "plt" and not v.isDir then
                            table.insert(strs, "----------------------")
                            table.insert(active, false)

                            table.insert(strs, "  set as theme")
                            table.insert(active, true)

                            screenshotY = screenshotY + 2
                        elseif devMode and v.exp == "app" and v.isDir then
                            table.insert(strs, "----------------------")
                            table.insert(active, false)

                            table.insert(strs, "  inside the package")
                            table.insert(active, true)

                            screenshotY = screenshotY + 2
                        elseif devMode and v.exp == "lua" and not v.isDir then
                            table.insert(strs, "----------------------")
                            table.insert(active, false)

                            table.insert(strs, "  edit")
                            table.insert(active, true)

                            screenshotY = screenshotY + 2
                        end

                        local posX, posY = window:toRealPos(windowEventData[3], windowEventData[4])

                        local clear = calls.call("screenshot", screen, posX, posY, 23, screenshotY)
                        local str, num = calls.call("gui_context", screen, posX, posY,
                        strs, active)

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
                                if #name ~= 0 and not name:find("%\\") and not name:find("%/") and
                                (not name:find("%.") or devMode) then --change expansion disabled
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
                        elseif str == "  edit" then
                            execute("edit", v.path)
                            draw()
                        else
                            clear()
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
            local clear = calls.call("screenshot", screen, posX, posY, 19, 7)
            local str, num = calls.call("gui_context", screen, posX, posY,
            {"  back", "  paste", "------------------", "  new image", "  new folder", "  new text file"},
            {true, not not copyObject, false, true, true, true})
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
                        if name:find("%.") or name:find("%/") or name:find("%\\") then
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
                        if (name:find("%.") and not devMode) or name:find("%/") or name:find("%\\") then
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
                        if (name:find("%.") and not devMode) or name:find("%/") or name:find("%\\") then
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
                    draw()
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