local fs = require("filesystem")
local bootloader = require("bootloader")
local computer = require("computer")
local component = require("component")
local programs = require("programs")
local gui = require("gui")
local paths = require("paths")
local registry = require("registry")
local graphic = require("graphic")
local time = require("time")
local system = require("system")
local serialization = require("serialization")
local gui_container = require("gui_container")
local event = require("event")
local unicode = require("unicode")
local thread = require("thread")
local cache = require("cache")
local natives = require("natives")
local colorlib = require("colors")
local liked = {}

local colors = gui_container.colors

function liked.getBranch()
    if fs.exists("/system/branch.cfg") then
        return fs.readFile("/system/branch.cfg")
    else
        return "main"
    end
end

function liked.setBranch(branch)
    return fs.writeFile("/system/branch.cfg", branch or "main")
end

--------------------------------------------------------

function liked.doFormats(appPath, path, delete)
    local data = assert(serialization.load(path))

    if not registry.data.gui_container then registry.data.gui_container = {} end
    if not registry.data.gui_container.knownExps then registry.data.gui_container.knownExps = {} end
    if not registry.data.gui_container.typecolors then registry.data.gui_container.typecolors = {} end
    if not registry.data.gui_container.typenames then registry.data.gui_container.typenames = {} end
    if not registry.data.gui_container.editable then registry.data.gui_container.editable = {} end
    if not registry.data.gui_container.openVia then registry.data.gui_container.openVia = {} end
    
    local function rmData(extension, key)
        registry.data.gui_container[key][extension] = nil
        gui_container[key][extension] = nil
    end

    for extension, formatInfo in pairs(data) do
        if delete then
            rmData(extension, "knownExps")
        else
            registry.data.gui_container.knownExps[extension] = true
        end

        if formatInfo.color then
            if delete then
                rmData(extension, "typecolors")
            else
                registry.data.gui_container.typecolors[extension] = formatInfo.color
            end
        else
            rmData(extension, "typecolors")
        end

        if formatInfo.name then
            if delete then
                rmData(extension, "typenames")
            else
                registry.data.gui_container.typenames[extension] = formatInfo.name
            end
        else
            rmData(extension, "typenames")
        end

        if formatInfo.editable then
            if delete then
                rmData(extension, "editable")
            else
                registry.data.gui_container.editable[extension] = true
            end
        else
            rmData(extension, "editable")
        end

        if formatInfo.program then
            if delete then
                rmData(extension, "openVia")
            else
                registry.data.gui_container.openVia[extension] = paths.xconcat(appPath, formatInfo.program)
            end
        else
            rmData(extension, "openVia")
        end

        if formatInfo.icon then
            if not registry.data.icons then
                registry.data.icons = {}
            end

            if delete then
                registry.data.icons[extension] = nil
            else
                registry.data.icons[extension] = paths.xconcat(appPath, formatInfo.icon)
            end
        end
    end

    registry.save()
    gui_container.refresh()
end

--------------------------------------------------------

function liked.isUninstallScript(path)
    return fs.exists(paths.concat(path, "uninstall.lua"))
end

function liked.isUninstallAvailable(path)
    if fs.isReadOnly(path) then return false end

    local data = "/data/"
    local vendor = "/vendor/"
    if path:sub(1, #data) == data then --вы всегда можете удалить приложения из data
        return true
    elseif path:sub(1, #vendor) == vendor then --вы можете удалить приложения вендора только если в нем есть uninstall.lua
        return liked.isUninstallScript(path)
    end
    return false
end

function liked.postInstall(screen, nickname, path)
    local regPath = paths.concat(path, "reg.reg")
    if fs.exists(regPath) and not fs.isDirectory(regPath) then
        liked.assert(screen, programs.execute("applyReg", screen, nickname, regPath, true))
    end

    local formatsPath = paths.concat(path, "formats.cfg")
    if fs.exists(formatsPath) and not fs.isDirectory(formatsPath) then
        liked.doFormats(path, formatsPath)
    end

    local installPath = paths.concat(path, "install.lua")
    if fs.exists(installPath) and not fs.isDirectory(installPath) then
        liked.assert(screen, programs.execute(installPath, screen, nickname))
    end

    registry.save()
    return true
end

function liked.uninstall(screen, nickname, path)
    local unregPath = paths.concat(path, "unreg.reg")
    if fs.exists(unregPath) and not fs.isDirectory(unregPath) then
        liked.assert(screen, programs.execute("applyReg", screen, nickname, unregPath, true))
    end

    local formatsPath = paths.concat(path, "formats.cfg")
    if fs.exists(formatsPath) and not fs.isDirectory(formatsPath) then
        liked.doFormats(path, formatsPath, true)
    end

    local uninstallPath = paths.concat(path, "uninstall.lua")
    if fs.exists(uninstallPath) and not fs.isDirectory(uninstallPath) then
        liked.assert(screen, programs.execute(uninstallPath, screen, nickname))
    else
        liked.assert(screen, fs.remove(path))
    end

    registry.save()
    return true
end

--------------------------------------------------------

function liked.lastVersion()
    local lastVersion, err = require("internet").getInternetFile("https://raw.githubusercontent.com/igorkll/liked/" .. liked.getBranch() .. "/system/version.cfg")
    if not lastVersion then return nil, err end
    return tonumber(lastVersion) or -1
end

function liked.version()
    return getOSversion()
end

function liked.umountAll()
    for address in component.list("filesystem") do
        if address ~= computer.tmpAddress() and address ~= fs.bootaddress then
            fs.umount(fs.genName(address))
        end
    end
end

function liked.mountAll()
    for address in component.list("filesystem") do
        if address ~= computer.tmpAddress() and address ~= fs.bootaddress then
            assert(fs.mount(address, fs.genName(address)))
        end
    end
end

--------------------------------------------------------

function liked.loadApp(name, screen, nickname)
    checkArg(1, name, "string")
    checkArg(2, screen, "string")
    checkArg(3, nickname, "string", "nil")

    local path = programs.find(name)
    if not path then
        return nil, "failed to launch application"
    end

    local isMain = paths.name(path) == "main.lua"

    --------------------------------

    local exitFile = paths.concat(paths.path(path), "exit.lua")
    if not isMain or not fs.exists(exitFile) or fs.isDirectory(exitFile) then
        exitFile = nil
    end


    local paletteFile = paths.concat(paths.path(path), "palette.plt")
    if not isMain or not fs.exists(paletteFile) or fs.isDirectory(paletteFile) then
        paletteFile = nil
    end


    local configFile = paths.concat(paths.path(path), "config.cfg")
    if not isMain or not fs.exists(configFile) or fs.isDirectory(configFile) then
        configFile = nil
    end


    local mainCode, err = programs.load(path)
    if not mainCode then return nil, err end

    --------------------------------

    local exitCode
    if exitFile then
        exitCode, err = programs.load(exitFile)
        if not exitCode then return nil, err end
    end

    local configTbl = {}
    if configFile then
        configTbl, err = serialization.load(configFile)
        if not configTbl then return nil, err end
    end

    --------------------------------

    local function log(tbl)
        if not tbl[1] then
            event.errLog("application error: " .. tostring(tbl[2] or "unknown error"))
        end
        return tbl
    end

    local function appStart()
        if paletteFile then
            log{pcall(system_applyTheme, paletteFile, screen)}
        end
    end

    local function appEnd()
        if configTbl.restoreGraphic then
            log{pcall(gui_initScreen, screen)}
        elseif paletteFile or configTbl.restorePalette then
            log{pcall(system_applyTheme, _G.initPalPath, screen)}
        end
    end

    return function (...)
        appStart()
        local result = log{thread.stub(mainCode, screen, nickname, ...)}
        appEnd()
        if exitCode then
            local result2 = log{thread.stub(exitCode, screen, nickname, ...)}
            if not result2[1] then
                if result[1] then
                    result[1] = false
                    result[2] = ""
                end
                result[2] = result[2] .. "; exit.lua err: " .. tostring(result2[2] or "unknown error")
            end
        end
        return table.unpack(result)
    end
end

function liked.execute(name, screen, nickname, ...)
    local code, err = liked.loadApp(name, screen, nickname)
    if code then
        local programTh = thread.createBackground(code, ...) --запуск программы в потоке чтобы созданые в ней потоки закрылись вместе с ней
        programTh:resume()
        local ok = true
        local err, out
        while true do
            if programTh:status() == "dead" then
                if not programTh.out[1] then --если ошибка произошла в функции которую возврашяет liked.loadApp (чего быть не должно)
                    ok, err = false, "osError: " .. (programTh.out[2] or "unknown error")
                elseif not programTh.out[2] then --если ошибка произошла в целевой программе
                    if programTh.out[3] then
                        ok, err = false, programTh.out[3]
                    end
                end
                out = {table.unpack(programTh.out, 2)}
                break
            end

            if not pcall(event.yield) then
                event.interruptFlag = programTh
            end
        end
        programTh:kill()

        if not ok then
            return ok, tostring(err or "unknown error")
        elseif out then
            return table.unpack(out)
        else
            return true
        end
    else
        return nil, tostring(err or "unknown error")
    end
end

--------------------------------------------------------

function liked.assert(screen, successful, err)
    if not successful then
        local clear = saveZone(screen)
        gui.warn(screen, nil, nil, err or "unknown error")
        clear()
    end
    return successful, err
end

function liked.assertNoClear(screen, successful, err)
    if not successful then
        gui.warn(screen, nil, nil, err or "unknown error")
    end
    return successful, err
end

--------------------------------------------------------

local bufferTimerId
function liked.applyBufferType()
    graphic.allowSoftwareBuffer = registry.bufferType == "software"
    graphic.allowHardwareBuffer = registry.bufferType == "hardware"
    graphic.vgpus = {}
    graphic.bindCache = {}
    graphic.screensBuffers = {}

    if graphic.allowHardwareBuffer or graphic.allowSoftwareBuffer then
        if not bufferTimerId then
            bufferTimerId = event.timer(0.1, graphic.forceUpdate, math.huge)
        end
    else
        if bufferTimerId then
            event.cancel(bufferTimerId)
            bufferTimerId = nil
        end
    end
end

local energyTh
local wakeupEvents = {
    touch = true,
    drop = true,
    drag = true,
    scroll = true,
    key_down = true,
    key_up = true
}
function liked.applyPowerMode()
    if registry.powerMode == "power" then
        event.minTime = 0
        if energyTh then
            energyTh:kill()
            energyTh = nil
        end
    else
        if not energyTh then
            energyTh = thread.createBackground(function ()
                local oldWakeTIme = computer.uptime()
                while true do
                    local eventData = {event.pull(1)}
                    if eventData[1] and wakeupEvents[eventData[1]] then
                        event.minTime = 0
                        oldWakeTIme = computer.uptime()
                    elseif computer.uptime() - oldWakeTIme > 2 then
                        event.minTime = 5
                    end
                end
            end)
            energyTh:resume()
        end
    end
end

function liked.applyBeepState()
    if registry.fullBeepDisable then
        computer.beep = system.stub
    else
        computer.beep = natives.computer.beep
    end
end

--------------------------------------------------------

function liked.raw_drawUpBarTask(method, screen, withoutFill, bgcolor)
    local function redraw()
        liked.drawUpBar(screen, withoutFill, bgcolor)
        graphic.updateFlag(screen)
    end
    local th = method(function ()
        while true do
            redraw()
            os.sleep(5)
        end
    end)
    th:resume()
    return th, redraw
end

function liked.drawUpBarTask(screen, withoutFill, bgcolor)
    return liked.raw_drawUpBarTask(require("thread").create, screen, withoutFill, bgcolor)
end

function liked.drawUpBarTaskBg(screen, withoutFill, bgcolor)
    return liked.raw_drawUpBarTask(require("thread").createBackground, screen, withoutFill, bgcolor)
end


function liked.drawUpBar(screen, withoutFill, bgcolor)
    local rtc = "RTC-" .. time.formatTime(time.addTimeZone(time.getRealTime(), registry.timeZone or 0))
    local gtc = "GTC-" .. time.formatTime(time.getGameTime())
    local charge = system.getCharge()
    
    local gpu = graphic.findGpu(screen)
    local rx, ry = gpu.getResolution()
    gpu.setBackground(bgcolor or gui_container.colors.gray)
    gpu.setForeground(gui_container.colors.white)
    if not withoutFill then
        gpu.fill(1, 1, rx, 1, " ")
    end

    local battery = "⣏⣉⣉⡷"
    local batteryLen = unicode.len(battery)
    local offset = batteryLen + 1

    gpu.set(rx - #rtc - 7 - offset, 1, rtc)
    gpu.set(rx - #gtc - 18 - offset, 1, gtc)
    if charge <= 30 then
        gpu.setForeground(gui_container.colors.red)
    end
    local chargestr = tostring(charge)
    gpu.set(rx - 5 - offset, 1, "   ")
    gpu.set(rx - #chargestr - 2 - offset, 1, tostring(chargestr) .. "%")

    gpu.setBackground(bgcolor or gui_container.colors.gray)
    gpu.setForeground(gui_container.colors.white)

    for i = 1, batteryLen do
        local char = unicode.sub(battery, i, i)
        if i == batteryLen then
            gpu.setBackground(bgcolor or gui_container.colors.gray)
        else
            if charge <= 30 then
                if i == 1 then
                    gpu.setBackground(gui_container.colors.red)
                else
                    gpu.setBackground(bgcolor or gui_container.colors.gray)
                end
            else
                local last = 3
                if charge <= 50 then
                    last = 1
                elseif charge <= 75 then
                    last = 2
                end

                if i <= last then
                    gpu.setBackground(gui_container.colors.lime)
                else
                    gpu.setBackground(bgcolor or gui_container.colors.gray)
                end
            end
        end
        gpu.set((rx - offset) + (i - 1), 1, char)
    end
end

--------------------------------------------------------

function liked.raw_drawFullUpBarTask(method, screen, ...)
    local args = {...}
    local function redraw()
        liked.drawFullUpBar(screen, table.unpack(args))
        graphic.updateFlag(screen)
    end
    local callbacks = {}
    local th = method(function ()
        thread.create(function ()
            local rx, ry = graphic.getResolution(screen)
            local window = graphic.createWindow(screen, 1, 1, rx, 1)
            while true do
                local eventData = {event.pull()}
                local windowEventData = window:uploadEvent(eventData)
                if windowEventData[1] == "touch" then
                    if windowEventData[3] == rx and callbacks.exit then
                        callbacks.exit()
                    end
                end
            end
        end):resume()

        while true do
            redraw()
            os.sleep(5)
        end
    end)
    th:resume()
    return th, redraw, callbacks
end

function liked.drawFullUpBarTask(...)
    return liked.raw_drawFullUpBarTask(thread.create, ...)
end

function liked.drawFullUpBarTaskBg(...)
    return liked.raw_drawFullUpBarTask(thread.createBackground, ...)
end

function liked.drawFullUpBar(screen, title, withoutFill, bgcolor)
    liked.drawUpBar(screen, withoutFill, bgcolor)
    local gpu = graphic.findGpu(screen)
    local rx, ry = gpu.getResolution()

    gpu.setForeground(gui_container.colors.white)
    if title then
        gpu.set(2, 1, title)
    end
    gpu.setBackground(gui_container.colors.red)
    gpu.set(rx, 1, "X")
end

--------------------------------------------------------

function liked.getRegistry(address)
    local mountpoint = os.tmpname()
    fs.mount(address or fs.get("/"), mountpoint)
    local regPath = paths.concat(mountpoint, "data/registry.dat")

    if fs.exists(regPath) or not fs.isDirectory(regPath) then
        local regData = fs.readFile(regPath)
        fs.umount(mountpoint)
        if regData then
            local ok, regTbl = pcall(serialization.unserialize, regData)
            if ok and type(regTbl) == "table" then
                return regTbl
            end
        end
    else
        fs.umount(mountpoint)
    end
end

function liked.labelReadonly(proxy)
    if type(proxy) == "string" then
        proxy = component.proxy(proxy)
    end
    return not pcall(proxy.setLabel, proxy.getLabel() or nil)
end

function liked.getName(screen, path)
    local name
    if gui_container.viewFileExps[screen] then
        name = paths.name(path)
    else
        name = paths.name(paths.hideExtension(path))
    end
    
    if unicode.len(name) > 12 then
        return unicode.sub(name, 1, 12) .. gui_container.chars.threeDots, name
    end
    return name, name
end

function liked.reg(str, key, value)
    gui_container[str][key] = value
    if not registry.gui_container then registry.gui_container = {} end
    if not registry.gui_container[str] then registry.gui_container[str] = {} end
    registry.gui_container[str][key] = value
    registry.save()
end

--------------------------------------------------------

function liked.getActions(path)
    local files, strs, actives = {}, {}, {}
    if fs.exists(path) and fs.isDirectory(path) then
        local actionPath = paths.concat(path, "actions.cfg") --раньше тут был lua файл, который выполнялся, но это слишком небезопастно

        if fs.exists(actionPath) and not fs.isDirectory(actionPath) then
            local content = fs.readFile(actionPath)
            if type(content) == "string" then
                local result = {pcall(serialization.unserialize, content)}
                event.yield() --предотващения краша при долгой десереализации

                if result and result[1] and type(result[2]) == "table" then
                    for _, value in ipairs(result[2]) do
                        if type(value) == "table" and type(value[1]) == "string" and type(value[3]) == "string" then
                            local action = value[1]
                            if unicode.len(action) < 24 then
                                table.insert(files, paths.xconcat(path, value[3]))
                                table.insert(strs, action)
                                table.insert(actives, not not value[2])
                                if #files >= 5 then --защита от приложений с большим количеством доп действий, так как это может использоваться для защиты от удаления
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return files, strs, actives
end

function liked.findIcon(name)
    cache.cache.findIcon = cache.cache.findIcon or {}
    if cache.cache.findIcon[name] then
        return cache.cache.findIcon[name]
    end

    if registry.icons and registry.icons[name] then
        return registry.icons[name]
    end

    local path = bootloader.find(paths.concat("icons", name .. ".t2p"))
    cache.cache.findIcon[name] = path
    return path
end

function liked.getIcon(screen, path)
    cache.cache.getIcon = cache.cache.getIcon or {}
    if cache.cache.getIcon[path] then
        if not fs.exists(path) then
            cache.cache.getIcon[path] = nil
            return liked.findIcon("badicon")
        end
        return cache.cache.getIcon[path]
    end

    local exp = paths.extension(path)
    local isDir = fs.isDirectory(path)
    local icon
    
    if isDir then
        local fsProxy, fsLocalPath = fs.get(path)
        if fsLocalPath ~= "/" then
            fsProxy = nil
        end
        if fsProxy then
            local disklevel = system.getDiskLevel(fsProxy.address)
            if disklevel == "tmp" then
                icon = liked.findIcon("tmp")
            elseif disklevel == "fdd" then
                if fsProxy.exists("/init.lua") then
                    icon = liked.findIcon("bootdevice")
                else
                    icon = liked.findIcon("fdd")
                end
            elseif disklevel == "raid" then
                icon = liked.findIcon("raid")
            elseif disklevel == "tier1" then
                icon = liked.findIcon("hdd1")
            elseif disklevel == "tier2" then
                icon = liked.findIcon("hdd2")
            elseif disklevel == "tier3" then
                icon = liked.findIcon("hdd3")
            else
                icon = liked.findIcon("hdd")
            end
        end

        local iconpath = paths.concat(path, "icon.t2p")
        if fs.exists(iconpath) and not fs.isDirectory(iconpath) then
            icon = iconpath
        elseif not fsProxy then
            if exp == "app" then
                icon = liked.findIcon("app")
            else
                icon = liked.findIcon("folder")
            end
        end
    else
        if exp == "t2p" then
            if path then
                local ok, sx, sy = pcall(gui_readimagesize, path)
                if ok and sx == 8 and sy == 4 then
                    icon = path
                else
                    icon = liked.findIcon("t2p")
                end
            else
                icon = liked.findIcon("t2p")
            end
        elseif exp and #exp > 0 then
            icon = liked.findIcon(exp)
            if not icon then
                icon = liked.findIcon("unknown")
            end
        else
            icon = liked.findIcon("file")
        end
    end

    if not icon or not fs.exists(icon) then
        icon = liked.findIcon("unknown")
    end

    local ok, sx, sy = pcall(gui_readimagesize, icon)
    if not ok or sx ~= 8 or sy ~= 4 then
        icon = nil
    end

    if not icon or not fs.exists(icon) then
        icon = liked.findIcon("badicon")
    end

    cache.cache.getIcon[path] = icon
    return icon
end

function liked.drawWallpaper(screen, customFolder)
    local baseColor = colors.lightBlue
    if registry.wallpaperBaseColor then
        if type(registry.wallpaperBaseColor) == "string" then
            baseColor = colors[registry.wallpaperBaseColor]
        elseif type(registry.wallpaperBaseColor) == "number" then
            baseColor = registry.wallpaperBaseColor
        end
    end

    local gpu = graphic.findGpu(screen)
    local rx, ry = gpu.getResolution()
    gpu.setBackground(baseColor)
    gpu.fill(1, 1, rx, ry, " ")

    local function wdraw(path)
        local ok, sx, sy = pcall(gui_readimagesize, path)
        if ok then
            local ix, iy = math.round((rx / 2) - (sx / 2)) + 1, math.round((ry / 2) - (sy / 2)) + 1
            pcall(gui_drawimage, screen, path, ix, iy)
        end
    end

    local wallpaperPath = "/data/wallpaper.t2p"
    local customPath = paths.concat(customFolder, paths.name(wallpaperPath))
    if fs.exists(customPath) then
        wdraw(customPath)
    elseif fs.exists(wallpaperPath) then
        wdraw(wallpaperPath)
    end
end

liked.unloadable = true
return liked