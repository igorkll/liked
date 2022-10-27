local fs = require("filesystem")
local paths = require("paths")
local event = require("event")
local component = require("component")
local computer = require("computer")

local function genName(uuid)
    return paths.concat("/data/userdata", (component.invoke(uuid, "getLabel") or "disk") .. "-" .. uuid:sub(1, 5))
end

if not vendor.doNotMoundDrives then
    event.listen("component_added", function(_, uuid, name)
        if name == "filesystem" then
            computer.beep(2000, 0.1)
            assert(fs.mount(uuid, genName(uuid)))
            event.push("redrawDesktop")
        end
    end)

    event.listen("component_removed", function(_, uuid, name)
        if name == "filesystem" then
            for _, tbl in ipairs(fs.mountList) do
                if tbl[1].address == uuid then
                    computer.beep(1000, 0.1)
                    assert(fs.umount(tbl[2]))
                    event.push("redrawDesktop")
                    break
                end
            end
        end
    end)

    for address in component.list("filesystem") do
        if address ~= computer.tmpAddress() and address ~= fs.bootaddress then
            assert(fs.mount(address, genName(address)))
        end
    end
end