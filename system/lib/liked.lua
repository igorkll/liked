local fs = require("filesystem")
local computer = require("computer")
local component = require("component")
local programs = require("programs")
local gui = require("gui")
local paths = require("paths")
local registry = require("registry")
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

    return function (...)
        local result = {xpcall(mainCode, debug.traceback, screen, nickname, ...)}
        pcall(exitCode, screen, nickname) --в exit.lua нет обработки ошибок
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

liked.unloadable = true
return liked