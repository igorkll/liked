local registry = require("registry")
local liked = require("liked")
local gui = require("gui")
local gui_container = require("gui_container")
local paths = require("paths")
local screen, _, path, force = ...

if not screen then
    if registry.apply(path) then
        gui_container.refresh()
        registry.save()
    end
elseif liked.publicMode(screen, path) then
    local name = gui.hideExtension(screen, path)
    if force or gui.yesno(screen, nil, nil, "do you really want to apply the \"" .. name .. "\" registry modifier?") then
        if not force then
            gui.status(screen, nil, nil, "installing reg file \"" .. name .. "\"")
        end
        if liked.assert(screen, registry.apply(path)) then
            gui_container.refresh()
            registry.save()
        end
    end
end