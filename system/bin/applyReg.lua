local registry = require("registry")
local liked = require("liked")
local gui = require("gui")
local gui_container = require("gui_container")
local paths = require("paths")
local screen, _, path, force = ...

if force or gui_yesno(screen, nil, nil, "do you really want to apply the \"" .. gui.hideExtension(screen, paths.name(path)) .. "\" registry modifier?") then
    gui.status(screen, nil, nil, "installing reg file \"" .. gui_container.toUserPath(screen, path) .. "\"")
    if liked.assert(screen, registry.apply(path)) then
        registry.hotReload()
        gui_container.refresh()
    end
end