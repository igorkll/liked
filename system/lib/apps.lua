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
local apps = {}

function apps.load(name, screen, nickname)
    checkArg(1, name, "string")
    checkArg(2, screen, "string")
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

                if configTbl.restoreResolution then
                    graphic.setResolution(screen, sysinit.getResolution(screen))
                end
            end

            if configTbl.noScreenSaver then
                screensaver.setEnabled(screen, oldScreenSaverState)
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

function apps.postInstall(screen, nickname, path)
    local regPath = paths.concat(path, "reg.reg")
    if fs.exists(regPath) and not fs.isDirectory(regPath) then
        liked.assert(screen, apps.execute("applyReg", screen, nickname, regPath, true))
    end

    local formatsPath = paths.concat(path, "formats.cfg")
    if fs.exists(formatsPath) and not fs.isDirectory(formatsPath) then
        doFormats(path, formatsPath)
    end

    local installPath = paths.concat(path, "install.lua")
    if fs.exists(installPath) and not fs.isDirectory(installPath) then
        liked.assert(screen, apps.execute(installPath, screen, nickname))
    end

    local autorunPath = paths.concat(path, "autorun.lua")
    if fs.exists(autorunPath) and not fs.isDirectory(autorunPath) then
        require("autorun").reg("system", autorunPath)
        apps.execute(autorunPath, screen, nickname)
    end

    registry.save()
    return true
end

function apps.uninstall(screen, nickname, path, hide)
    if not hide then
        gui.status(screen, nil, nil, "uninstalling \"" .. gui.hideExtension(screen, path) .. "\"...")
    end

    local unregPath = paths.concat(path, "unreg.reg")
    if fs.exists(unregPath) and not fs.isDirectory(unregPath) then
        liked.assert(screen, apps.execute("applyReg", screen, nickname, unregPath, true))
    end

    local formatsPath = paths.concat(path, "formats.cfg")
    if fs.exists(formatsPath) and not fs.isDirectory(formatsPath) then
        doFormats(path, formatsPath, true)
    end

    local uninstallPath = paths.concat(path, "uninstall.lua")
    if fs.exists(uninstallPath) and not fs.isDirectory(uninstallPath) then
        liked.assert(screen, apps.execute(uninstallPath, screen, nickname))
    else
        liked.assert(screen, fs.remove(path))
    end

    local autorunPath = paths.concat(path, "autorun.lua")
    if fs.exists(autorunPath) and not fs.isDirectory(autorunPath) then
        require("autorun").reg("system", autorunPath, true)
    end

    registry.save()
    return true
end

local function appList()
    local list = {}
    for _, name in ipairs(fs.list("/data/apps")) do
        list[name] = true
    end
    return list
end

function apps.install(screen, nickname, path, hide)
    if not hide then
        local name = gui.hideExtension(screen, path)
        if not gui.yesno(screen, nil, nil, "Are you sure you want to install the \"" .. name .."\" package?") then return false, "cancel" end
        gui.status(screen, nil, nil, "installing \"" .. name .. "\"...")
    end

    local oldAppList = appList()
    local ok, err = archiver.unpack(path, "/data")
    if not ok then return nil, err end
    for appName in pairs(appList()) do --тут есть проблема, если через xpkg обновить приложения, то postInstall не запуститься
        if not oldAppList[appName] then
            local fullpath = paths.concat("/data/apps", appName)
            apps.postInstall(screen, nickname, fullpath)
        end
    end

    return true
end

apps.unloadable = true
return apps