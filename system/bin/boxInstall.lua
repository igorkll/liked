local installer = require("installer")
local gui = require("gui")

local screen, nickname, path = ...
local clear = gui.saveBigZone(screen)
local vfs = gui.selectExternalFs(screen)
if not vfs then return end
clear()
local ok, err = installer.ui_install_boxfile(screen, vfs, path)
if not ok then
    gui.bigWarn(screen, nil, nil, err)
end