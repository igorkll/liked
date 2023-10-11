local registry = require("registry")
local liked = require("liked")
local gui = require("gui")
local screen, _, path = ...

gui.status(screen, nil, nil, "installing reg file \"" .. gui_container.toUserPath(screen, path) .. "\"")
liked.assert(screen, registry.apple(path))