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

function liked.mountAll()
    for address in component.list("filesystem") do
        if address ~= computer.tmpAddress() and address ~= fs.bootaddress then
            assert(fs.mount(address, fs.genName(address)))
        end
    end
end

function liked.remountAll()
    liked.umountAll()
    liked.mountAll()
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
    if exitFile then
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
    else
        return true
    end
end

function liked.applyBufferType()
    graphic.allowSoftwareBuffer = registry.bufferType == "software"
    graphic.allowHardwareBuffer = registry.bufferType == "hardware"
    graphic.vgpus = {}
    graphic.bindCache = {}
    graphic.screensBuffers = {}
end

function liked.applyPowerMode()
    local powerModes = {
        ["ultra power"] = 0,
        ["power"] = 0.05,
        ["energy saving"] = 0.5,
        ["ultra energy saving"] = 2,
    }
    event.minTime = powerModes[registry.powerMode]
end

function liked.raw_drawUpBarTask(method, screen, withoutFill, bgcolor)
    local function redraw()
        liked.drawUpBar(screen, withoutFill, bgcolor)
        graphic.update(screen)
    end
    local th = method(function ()
        while true do
            redraw()
            os.sleep(10)
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

liked.unloadable = true
return liked