local registry = require("registry")
if not registry.password then return end

local screen = ...

local liked = require("liked")
local gui = require("gui")

liked.drawFullUpBarTask(screen)
liked.drawWallpaper(screen)
gui.checkPasswordLoop(screen, nil, nil, true)