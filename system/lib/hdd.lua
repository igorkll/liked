local fs = require("filesystem")
local component = require("component")
local hdd = {}

function hdd.get(proxy)
    if type(proxy) == "string" then
        return component.proxy(proxy)
    end
    return proxy
end

function hdd.move(from, to)
    from = hdd.get(from)
    to = hdd.get(to)
    fs.umount("/mnt/from")
    fs.umount("/mnt/to")
    fs.mount("/mnt/from", from)
    fs.mount("/mnt/to", to)
    fs.copy("/mnt/from", "/mnt/to")
    fs.umount("/mnt/from")
    fs.umount("/mnt/to")
end

hdd.unloadable = true
return hdd