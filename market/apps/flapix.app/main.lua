local graphic = require("graphic")
local liked = require("liked")

local screen = ...
local pal = liked.colors
local window = graphic.createWindow(screen, 1, 1, graphic.getResolution(screen))
liked.regExit(screen)

local birdPosX = 15
local birdPosY = 0

while true do
    window:clear(pal.lightBlue)
    window:fill(birdPosX, birdPosY, 2, 1, pal.yellow, pal.yellow, " ")
    os.sleep(0.1)
end