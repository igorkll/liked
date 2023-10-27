local registry = require("registry")
local liked = require("liked")
local gui = require("gui")
local gui_container = require("gui_container")
local paths = require("paths")
local screen, _, path, force = ...

if force or gui_yesno(screen, nil, nil, "do you really want to apply the \"" .. gui.hideExtension(screen, paths.name(path)) .. "\" registry modifier?") then
    if not force then
        gui.status(screen, nil, nil, "installing reg file \"" .. gui_container.toUserPath(screen, path) .. "\"")
    end
    if liked.assert(screen, registry.apply(path)) then
        gui_container.refresh()
        registry.save()
    end
end