local registry = require("registry")
local liked = require("liked")
local gui = require("gui")
local gui_container = require("gui_container")
local screen, _, path = ...

local upath = gui_container.toUserPath(screen, path)
if gui_yesno(screen, nil, nil, "do you really want to apply the " .. upath .. " registry modifier?") then
    gui.status(screen, nil, nil, "installing reg file \"" .. upath .. "\"")
    liked.assert(screen, registry.apply(path))
end