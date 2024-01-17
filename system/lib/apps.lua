local liked = require("liked")
local paths = require("paths")
local programs = require("programs")
local fs = require("filesystem")
local serialization = require("serialization")
local palette = require("palette")
local screensaver = require("screensaver")
local graphic = require("graphic")
local sysinit = require("sysinit")
local thread = require("thread")
local event = require("event")
local registry = require("registry")
local gui = require("gui")
local gui_container = require("gui_container")
local archiver = require("archiver")
local component = require("component")
local text = require("text")
local unicode = require("unicode")
local apps = {}

local installedInfo = registry.new("/data/installedInfo.dat")
local appsPath = "/data/apps/"
local shadowPath = "/data/applicationsShadow/"

local function appList(folder)
    local list = {}
    for _, name in ipairs(fs.list(folder)) do
        local fullpath = paths.concat(folder, name)
        if fs.isDirectory(fullpath) then
            list[paths.name(name)] = true
        end
    end
    return list
end

local function createShadow(appName)
    fs.makeDirectory(paths.concat(shadowPath, appName))

    local function move(file)
        fs.copy(paths.concat(appsPath, appName, file), paths.concat(shadowPath, appName, file))
    end
    
    move("unreg.reg")
    move("formats.cfg")
    move("uninstall.lua")
end

local function doFormats(appPath, path, delete)
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

--------------------------------------------

function apps.load(name, screen, nickname)
    checkArg(1, name, "string")
    checkArg(2, screen, "string", "nil")
    checkArg(3, nickname, "string", "nil")

    local path = programs.find(name)
    if not path then
        return nil, "failed to launch application"
    end

    if not liked.isExecuteAvailable(path) then
        return nil, "application cannot be started"
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

    --------------------------------

    local mainCode, err = programs.load(path)
    if not mainCode then return nil, err end

    local exitCode
    if exitFile then
        exitCode, err = programs.load(exitFile)
        if not exitCode then return nil, err end
    end

    local configTbl = {}
    if configFile then
        configTbl, err = serialization.load(configFile)
        if not configTbl then return nil, err end

        if configTbl.palette then
            paletteFile = configTbl.palette
        end
    end

    local oldScreenSaverState
    local oldPrecise

    --------------------------------

    local function log(tbl)
        if not tbl[1] then
            event.errLog("application error: " .. tostring(tbl[2] or "unknown error"))
        end
        return tbl
    end

    local function appStart()
        if screen then
            if paletteFile then
                palette.fromFile(screen, paletteFile, configTbl.dontRegPalette)
            elseif configTbl.blackWhite then
                palette.blackWhite(screen, true)
            end

            if configTbl.noScreenSaver then
                oldScreenSaverState = screensaver.isEnabled(screen)
                screensaver.setEnabled(screen, false)
            end

            if configTbl.res then
                graphic.setResolution(screen, table.unpack(configTbl.res))
            end

            if configTbl.precise ~= nil and graphic.getDeviceTier(screen) == 3 then
                oldPrecise = not not component.invoke(screen, "isPrecise")
                component.invoke(screen, "setPrecise", configTbl.precise)
            end
        end
    end

    local function appEnd()
        if screen then
            if configTbl.restoreGraphic then
                log{pcall(sysinit.initScreen, screen)}
            else
                if paletteFile or configTbl.restorePalette or configTbl.blackWhite then
                    palette.system(screen)
                end

                if configTbl.restoreResolution or configTbl.res then
                    graphic.setResolution(screen, sysinit.getResolution(screen))
                end
            end

            if configTbl.noScreenSaver then
                screensaver.setEnabled(screen, oldScreenSaverState)
            end

            if oldPrecise ~= nil then
                component.invoke(screen, "setPrecise", oldPrecise)
            end
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

function apps.execute(name, screen, nickname, ...)
    local code, err = apps.load(name, screen, nickname)
    if code then
        local programTh = thread.create(code, ...) --запуск программы в потоке чтобы созданые в ней потоки закрылись вместе с ней
        programTh.parentData.screen = screen
        programTh:resume()
        local ok = true
        local err, out
        while true do
            if programTh:status() == "dead" then
                if not programTh.out[1] then --если ошибка произошла в функции которую возврашяет apps.load (чего быть не должно)
                    ok, err = false, "osError: " .. (programTh.out[2] or "unknown error")
                elseif not programTh.out[2] then --если ошибка произошла в целевой программе
                    if programTh.out[3] then
                        ok, err = false, programTh.out[3]
                    end
                end
                out = {table.unpack(programTh.out, 2)}
                break
            end

            event.yield()
        end
        programTh:kill()

        if not ok then
            return nil, tostring(err or "unknown error")
        elseif out then
            return table.unpack(out)
        else
            return true
        end
    else
        return nil, tostring(err or "unknown error")
    end
end

function apps.executeWithWarn(name, screen, nickname, ...)
    local result = {apps.execute(name, screen, nickname, ...)}
    if screen and not result[1] then
        local clear = gui.saveBigZone(screen)
        gui.bigWarn(screen, nil, nil, tostring(result[2] or "unknown error"))
        clear()
    end
    return table.unpack(result)
end

function apps.postInstall(screen, nickname, path, version)
    local function lassert(...)
        if screen then
            liked.assert(screen, ...)
        end
    end

    local regPath = paths.concat(path, "reg.reg")
    if fs.exists(regPath) and not fs.isDirectory(regPath) then
        lassert(apps.execute("applyReg", screen, nickname, regPath, true))
    end

    local formatsPath = paths.concat(path, "formats.cfg")
    if fs.exists(formatsPath) and not fs.isDirectory(formatsPath) then
        doFormats(path, formatsPath)
    end

    local installPath = paths.concat(path, "install.lua")
    if fs.exists(installPath) and not fs.isDirectory(installPath) then
        lassert(apps.execute(installPath, screen, nickname))
    end

    local autorunPath = paths.concat(path, "autorun.lua")
    if fs.exists(autorunPath) and not fs.isDirectory(autorunPath) then
        require("autorun").reg("system", autorunPath)
        apps.execute(autorunPath, screen, nickname)
    end

    createShadow(paths.name(path))
    installedInfo.data[paths.name(path)] = tostring(version or "unknown")
    installedInfo.save()
    registry.save()
    return true
end

function apps.uninstall(screen, nickname, path, hide)
    local function lassert(...)
        if screen then
            liked.assert(screen, ...)
        end
    end

    if not hide and screen then
        gui.status(screen, nil, nil, "uninstalling \"" .. gui.hideExtension(screen, path) .. "\"...")
    end

    local unregPath = paths.concat(path, "unreg.reg")
    if fs.exists(unregPath) and not fs.isDirectory(unregPath) then
        lassert(apps.execute("applyReg", screen, nickname, unregPath, true))
    end

    local formatsPath = paths.concat(path, "formats.cfg")
    if fs.exists(formatsPath) and not fs.isDirectory(formatsPath) then
        doFormats(path, formatsPath, true)
    end

    local uninstallPath = paths.concat(path, "uninstall.lua")
    if fs.exists(uninstallPath) and not fs.isDirectory(uninstallPath) then
        lassert(apps.execute(uninstallPath, screen, nickname))
    else
        lassert(fs.remove(path))
    end

    local autorunPath = paths.concat(path, "autorun.lua")
    if fs.exists(autorunPath) and not fs.isDirectory(autorunPath) then
        require("autorun").reg("system", autorunPath, true)
    end

    if not fs.exists(path) then
        if text.startwith(unicode, path, appsPath) then
            fs.remove(paths.concat(shadowPath, paths.name(path)))
        end
        installedInfo.data[paths.name(path)] = nil
        installedInfo.save()
    end
    registry.save()
    return true
end

function apps.install(screen, nickname, path, hide)
    if not hide then
        local name = gui.hideExtension(screen, path)
        if not gui.yesno(screen, nil, nil, "Are you sure you want to install the \"" .. name .."\" package?") then return false, "cancel" end
        gui.status(screen, nil, nil, "installing \"" .. name .. "\"...")
    end

    local ok, err = archiver.unpack(path, "/data")
    if ok then
        apps.check()
    end
    return ok, err
end

function apps.check()
    local installedApps = appList(appsPath)
    local shadowApps = appList(shadowPath)

    for name in pairs(installedApps) do
        if not shadowApps[name] then
            createShadow(name)
        end

        if not installedInfo.data[name] then
            apps.postInstall(nil, nil, paths.concat(appsPath, name))
        end
    end

    for name in pairs(installedInfo.data) do
        if not installedApps[name] then
            local lpath = paths.concat(shadowPath, name)
            if fs.isDirectory(lpath) then
                apps.uninstall(nil, nil, lpath)
            end
        end
    end
end

apps.unloadable = true
return apps