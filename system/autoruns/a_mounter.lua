local fs = require("filesystem")
local paths = require("paths")
local event = require("event")
local computer = require("computer")

local function genName()
    local number = 1
    while true do
        if fs.exists(paths.concat("/data/userdata", "disk" .. tostring(number))) then
            number = number + 1
        else
            break
        end
    end
    return paths.concat("/data/userdata", "disk" .. tostring(number))
end

event.listen("component_added", function(_, uuid, name)
    if name == "filesystem" then
        computer.beep(2000, 0.1)
        assert(fs.mount(uuid, genName()))
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