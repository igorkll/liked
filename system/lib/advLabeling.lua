local registry = require("registry")
local component = require("component")
local advLabeling = {}

function advLabeling.setLabel(address, label)
    local result = {pcall(component.invoke, address, "setLabel", label)}
    if not result[1] or type(result[2]) ~= "string" then --если например в tape_drive нет касеты, но установиться label самого tape_drive, а если есть касета то тогда label касеты установиться
        if not registry.advLabeling then registry.advLabeling = {} end
        registry.advLabeling[address] = label
        registry.save()
    end
end

function advLabeling.getLabel(address)
    local result = {pcall(component.invoke, address, "getLabel")}

    local label
    if result[1] and type(result[2]) == "string" then
        label = result[2]
    elseif registry.advLabeling and registry.advLabeling[address] then
        label = registry.advLabeling[address]
    end
    return label
end

advLabeling.unloaded = true
return advLabeling