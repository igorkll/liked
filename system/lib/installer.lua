local fs = require("filesystem")
local registry = require("registry")
local gui = require("gui")
local paths = require("paths")
local liked = require("liked")
local graphic = require("graphic")
local installer = {}

local targetsys = "/mnt/tmpmount"
local selfsys = "/mnt/selfsys"

----------------------------------------------------------------------

function installer.init(vfs)
    local rootfs = fs.get("/")

    fs.umount(targetsys)
    fs.umount(selfsys)

    local success, err = fs.mount(vfs, targetsys)
    if not success then return nil, err end

    local success, err = fs.mount(rootfs, selfsys)
    if not success then return nil, err end

    return true
end

function installer.uinit(vfs, label, ...)
    pcall(vfs.setLabel, label)
    fs.umount(targetsys)
    fs.umount(selfsys)
    return ...
end

function installer.selfPath(path)
    return paths.concat(selfsys, path)
end

function installer.targetPath(path)
    return paths.concat(targetsys, path)
end

function installer.toTarget(path)
    return fs.copy(installer.selfPath(path), installer.targetPath(path))
end

function installer.rmTarget(path)
    return fs.remove(installer.targetPath(path))
end

----------------------------------------------------------------------

function installer.install_core(vfs)
    local success, err = installer.init(vfs)
    if not success then return nil, err end

    local success, err = installer.toTarget("init.lua")
    if not success then return nil, err end

    installer.rmTarget("system/core") --удаляю старое ядра чтобы не было канфликтов версий и не оставалось лишних файлов
    return installer.uinit(vfs, "likeOS", installer.toTarget("system/core"))
end

function installer.install_liked(vfs)
    local success, err = installer.init(vfs)
    if not success then return nil, err end

    local success, err = installer.toTarget("init.lua")
    if not success then return nil, err end

    installer.rmTarget("system") --удаляю старую систему чтобы не было канфликтов версий и не оставалось лишних файлов
    return installer.uinit(vfs, "liked", installer.toTarget("system"))
end

function installer.install_likedbox(vfs)
    local success, err = installer.init(vfs)
    if not success then return nil, err end

    local success, err = installer.toTarget("init.lua")
    if not success then return nil, err end

    installer.rmTarget("system") --удаляю старую систему чтобы не было канфликтов версий и не оставалось лишних файлов

    local bl = {
        "installer",
        "likedbox",
        "screenSavers",
        "themes",
        "wallpapers",
        "icons",
        "bin",
        "autoruns",
        "recoveryScript.lua",
        "registry.dat",
        "market_urls_dev.txt",
        "market_urls_main.txt",
        "logo.lua",
        "lib/installer.lua"
    }
    
    local systemFolder = installer.selfPath("system")
    local targetSystemFolder = installer.targetPath("system")
    local success, err = fs.copy(systemFolder, targetSystemFolder, function (from)
        for _, lpath in ipairs(bl) do
            if paths.equals(paths.concat(systemFolder, lpath), from) then
                return false
            end
        end
        
        return true
    end)
    if not success then return nil, err end

    return installer.uinit(vfs, "likedbox", fs.copy(installer.selfPath("system/likedbox"), targetSystemFolder))
end

----------------------------------------------------------------------

function installer.context(screen, posX, posY, vfs)
    gui.contextAuto(screen, posX, posY, {
        "  likeOS installer",
        "  liked",
        "  likedbox",
        "  likeOS (core only)",
        "  full cloning of the system  "
    })

    local name = fs.genName(vfs.address)
end

installer.unloadable = true
return installer