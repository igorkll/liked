local paths = require("paths")
local system = require("system")

local screen, nickname = ...
local selfpath = paths.concat(paths.path(system.getSelfScriptPath()), "main.lua")
require("programs").execute(selfpath, screen, nickname, nil, true)