local fs = require("filesystem")
local paths = require("paths")
local event = require("event")
local component = require("component")
local computer = require("computer")
local registry = require("registry")

local invoke = component.invoke
local externalPath = "/external-data/devicetype.dat"
function fs.genName(uuid)
    local label = invoke(uuid, "getLabel")
    if label then
        label = label:sub(1, 8)
    else
        local externalData
        if invoke(uuid, "exists", externalPath) then
            local file = invoke(uuid, "open", externalPath, "rb")
            externalData = invoke(uuid, "read", file, math.huge)
            invoke(uuid, "close", file)
        end
        label = externalData or "disk"
    end
    return paths.concat("/data/userdata", label .. "-" .. uuid:sub(1, 5))
end

if not registry.doNotMoundDisks then
    local function allowMount(address)
        return address ~= computer.tmpAddress() and address ~= fs.bootaddress
    end

    event.listen("component_added", function(_, uuid, name)
        if name == "filesystem" and allowMount(uuid) then
            if registry.soundEnable then
                computer.beep(2000, 0.1)
            end
            assert(fs.mount(uuid, fs.genName(uuid)))
            event.push("redrawDesktop")
        end
    end)

    event.listen("component_removed", function(_, uuid, name)
        if name == "filesystem" and allowMount(uuid) then
            for _, tbl in ipairs(fs.mountList) do
                if tbl[1].address == uuid then
                    if registry.soundEnable then
                        computer.beep(1000, 0.1)
                    end
                    assert(fs.umount(tbl[2]))
                    event.push("redrawDesktop")
                    break
                end
            end
        end
    end)
    
    for address in component.list("filesystem") do
        if allowMount(address) then
            assert(fs.mount(address, fs.genName(address)))
        end
    end
end