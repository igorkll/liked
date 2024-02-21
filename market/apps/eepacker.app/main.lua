local iowindows = require("iowindows")
local gui = require("gui")
local fs = require("filesystem")

local screen = ...
local path = iowindows.selectfile(screen, "lua")
if not path then return end
