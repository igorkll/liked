local installer = require("installer")
local gui = require("gui")

local screen, nickname, path = ...
local vfs = gui.selectExternalFs(screen)
if not vfs then return end
local ok, err = installer.install_boxfile(vfs, path)
if not ok then
    gui.bigWarn(screen, nil, nil, err)
end