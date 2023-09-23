local fs = require("filesystem")
local computer = require("computer")
local component = require("component")
local programs = require("programs")
local gui = require("gui")
local liked = {}

function liked.lastVersion()
    local lastVersion, err = require("internet").getInternetFile("https://raw.githubusercontent.com/igorkll/liked/main/system/version.cfg")
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
    if not path or not fs.exists(path) or fs.isDirectory(path) then
        gui.warn(screen, nil, nil, "failed to launch application")
        draw()
        return
    end
    if fs.exists("/vendor/appChecker.lua") then
        local out = {programs.execute("/vendor/appChecker.lua", screen, nickname, path)}
        if not out[1] then
            gui.warn(screen, nil, nil, out[2])
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

liked.unloadable = true
return liked