local uix = require("uix")
local system = require("system")

local screen = ...
local gamePath = system.getResourcePath("game.lua")
local ui = uix.manager(screen)
local rx, ry = ui:zoneSize()
local layout = ui:create("Flapix", uix.colors.brown)

function layout:onRedraw()
    self.window:fill(1, 2, self.window.sizeX, self.window.sizeY - 2, uix.colors.lightBlue, 0, " ")
    self.window:fill(15, 8, 2, 1, uix.colors.yellow, 0, " ")
end

local startGame = layout:createButton(math.round((rx / 2) - 7), math.round(ry / 2) - 1, 16, 3, uix.colors.lightGray, uix.black, "start game", true)
function startGame:onClick(_, nickname)
    ui:execute(gamePath, screen, nickname)
end

ui:loop()