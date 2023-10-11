local fs = require("filesystem")
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
local liked = {}

function liked.lastVersion()
    local lastVersion, err = require("internet").getInternetFile("https://raw.githubusercontent.com/igorkll/liked/" .. registry.branch .. "/system/version.cfg")
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

function liked.loadApp(name, screen, nickname)
    local path = programs.find(name)
    if not path then
        return nil, "failed to launch application"
    end

    local exitFile = paths.concat(paths.path(path), "exit.lua")
    if not fs.exists(exitFile) or fs.isDirectory(exitFile) then
        exitFile = nil
    end

    local mainCode, err = programs.load(path)
    if not mainCode then return nil, err end
    local exitCode
    if exitFile and paths.name(path) == "main.lua" then
        exitCode, err = programs.load(exitFile)
        if not exitCode then return nil, err end
    end

    local function log(tbl)
        if not tbl[1] then
            event.errLog("application error: " .. tostring(tbl[2]))
        end
        return tbl
    end

    return function (...)
        local result = log{xpcall(mainCode, debug.traceback, screen, nickname, ...)}
        if exitCode then
            local result2 = log{xpcall(exitCode, debug.traceback, screen, nickname, ...)}
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
    local rtc = "RTC-" .. time.formatTime(time.addTimeZone(time.getRealTime(), registry.timeZone))
    local gtc = "GTC-" .. time.formatTime(time.getGameTime())
    local charge = system.getCharge()
    
    local gpu = graphic.findGpu(screen)
    local rx, ry = gpu.getResolution()
    gpu.setBackground(bgcolor or gui_container.colors.gray)
    gpu.setForeground(gui_container.colors.white)
    if not withoutFill then
        gpu.fill(1, 1, rx, 1, " ")
    end
    gpu.set(rx - #rtc - 7, 1, rtc)
    gpu.set(rx - #gtc - 18, 1, gtc)
    if charge <= 30 then
        gpu.setForeground(gui_container.colors.red)
    end
    charge = tostring(charge)
    gpu.set(rx - 5, 1, "   ")
    gpu.set(rx - #charge - 2, 1, tostring(charge) .. "%")
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

function liked.findIcon(name)
    if registry.icons and registry.icons[name] then
        return registry.icons[name]
    end

    local path = paths.concat("/data/icons", name .. ".t2p")
    if fs.exists(path) then
        return path
    end
    path = paths.concat("/system/icons", name .. ".t2p")
    if fs.exists(path) then
        return path
    end
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

function liked.getIcon(screen, path)
    local exp = paths.extension(path)
    local isDir = fs.isDirectory(path)
    local icon
    local fsProxy

    for _, tbl in ipairs(fs.mountList) do
        if paths.canonical(path) .. "/" == tbl[2] then
            fsProxy = tbl[1]

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
            break
        end
    end
    
    
    if isDir then
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
    end

    if not fsProxy and not isDir then
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

    --if not icon or not fs.exists(icon) then
    --    icon = liked.findIcon("unknown")
    --end

    --[[
    do --check icon
        local ok, sx, sy = pcall(gui_readimagesize, icon)
        if not ok or sx ~= 8 or sy ~= 4 then
            icon = nil
        end
    end
    ]]

    if not icon or not fs.exists(icon) or fs.isDirectory(icon) then
        icon = liked.findIcon("badicon")
    end

    return icon
end

function liked.reg(str, key, value)
    gui_container[str][key] = value
    if not registry.gui_container then registry.gui_container = {} end
    if not registry.gui_container[str] then registry.gui_container[str] = {} end
    registry.gui_container[str][key] = value
    registry.save()
end

liked.unloadable = true
return liked