local zximage = require("zximage")
local iowindows = require("iowindows")
local gui = require("gui")
local liked = require("liked")
local graphic = require("graphic")
local sysinit = require("sysinit")

local screen, _, path = ...
path = path or iowindows.selectfile(screen, "scr")
if not path then
    return
end

local ok, err = zximage.check(path)
if not ok then
    gui.warn(screen, nil, nil, err)
    return
end

local crop = graphic.getDepth(screen) < 8
zximage.applyResolution(screen, crop)
zximage.applyPalette(screen)
zximage.draw(screen, path, crop)
liked.wait()
pcall(sysinit.initScreen, screen)