local fs = require("filesystem")
local paths = require("paths")
local event = require("event")

local function genName()
    local number = 1
    while true do
        if fs.exists("disk" .. tostring(number)) then
            number = number + 1
        else
            break
        end
    end
    return "disk" .. tostring(number)
end

event.listen("component_added", function(_, uuid, name)
    if name == "filesystem" then
        fs.mount(uuid, paths.concat("/data/userdata", genName()))
        event.push("redrawDesktop")
    end
end)

event.listen("component_added", function(_, uuid, name)
    if name == "filesystem" then
        for name
    end
end)