local uix = require("uix")
local system = require("system")
local storage = require("storage")
local gui = require("gui")

local screen = ...
local conf = storage.getConf({bestScore = 0})
local gamePath = system.getResourcePath("game.lua")
local ui = uix.manager(screen)
local rx, ry = ui:zoneSize()
local layout = ui:create("Flapix", uix.colors.brown)

function layout:onRedraw()
    self.window:fill(1, 2, self.window.sizeX, self.window.sizeY - 2, uix.colors.lightBlue, 0, " ")
    self.window:fill(20, 8, 2, 1, uix.colors.yellow, 0, " ")
    gui.drawtext(screen, 2, 4, uix.colors.white, "score     : 0")
    gui.drawtext(screen, 2, 5, uix.colors.white, "best score: " .. conf.bestScore)
end

local startGame = layout:createButton(math.round((rx / 2) - 7), math.round(ry / 2) - 1, 16, 3, uix.colors.lightGray, uix.black, "start game", true)
function startGame:onClick(_, nickname)
    assert(ui:execute(gamePath, screen, nickname))
end

ui:loop()