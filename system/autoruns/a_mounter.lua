local fs = require("filesystem")
local paths = require("paths")
local event = require("event")
local component = require("component")
local computer = require("computer")
local registry = require("registry")
local bootloader = require("bootloader")

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

    local mountlist = {}

    event.listen("component_added", function(_, uuid, name)
        if name == "filesystem" and allowMount(uuid) then
            if bootloader.runlevel ~= "init" then
                if registry.soundEnable then
                    computer.beep(2000, 0.1)
                end
                event.push("redrawDesktop")
            end
            local mountpoint = fs.genName(uuid)
            assert(fs.mount(uuid, mountpoint))
            mountlist[uuid] = mountpoint
        end
    end)

    event.listen("component_removed", function(_, uuid, name)
        local gui_container = require("gui_container")
        if name == "filesystem" and allowMount(uuid) then
            gui_container.unlockedDisks[uuid] = nil
            if mountlist[uuid] then
                if bootloader.runlevel ~= "init" then
                    if registry.soundEnable then
                        computer.beep(1000, 0.1)
                    end
                    event.push("redrawDesktop")
                end
                assert(fs.umount(mountlist[uuid]))
                mountlist[uuid] = nil
            end
        end
    end)
end