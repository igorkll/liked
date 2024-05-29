local screen = ...
local component = require("component")
local fs = require("filesystem")

fs.writeFile("/tmp/bootloader/bootfile", "/mineOS.lua")
require("bootloader").initScreen(component.gpu, screen)
require("natives").computer.shutdown("fast")