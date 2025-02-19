local screen = ...
local component = require("component")
local fs = require("filesystem")

fs.writeFile("/tmp/bootloader/bootfile", "/openOS.lua")
require("bootloader").initScreen(component.gpu, screen)

local computer = require("natives").computer
computer.setArchitecture("Lua 5.2")
computer.shutdown("fast")