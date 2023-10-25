local fs = require("filesystem")
local registry = require("registry")
local gui = require("gui")
local paths = require("paths")
local liked = require("liked")
local graphic = require("graphic")
local installer = {}

local targetsys = "/mnt/tmpmount"
local selfsys = "/mnt/selfsys"

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

function installer.uinit(...)
    fs.umount(targetsys)
    fs.umount(selfsys)
    return ...
end

function installer.install_core(vfs)
    local success, err = installer.init(vfs)
    if not success then return nil, err end

    local success, err = fs.copy(paths.concat(selfsys, "init.lua"), paths.concat(targetsys, "init.lua"))
    if not success then return nil, err end

    fs.remove(paths.concat(targetsys, "system/core")) --удаляею старое ядра чтобы не было канфликтов версий и не оставалось лишних файлов
    return installer.uinit(fs.copy(paths.concat(selfsys, "system/core"), paths.concat(targetsys, "system/core")))
end

return installer