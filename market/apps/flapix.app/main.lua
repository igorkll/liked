local uix = require("uix")
local system = require("system")

local screen = ...
local gamePath = system.getResourcePath("game.lua")
local ui = uix.manager(screen)
local rx, ry = ui:zoneSize()
local layout = ui:create("Flapix", uix.colors.brown)

function layout:onRedraw()
    self.window:fill(1, 2, self.window.sizeX, self.window.sizeY - 2, uix.colors.lightBlue, 0, " ")
    for i = 1, 3 do
        local col = uix.colors.yellow
        local r = math.random(1, 7)
        if i == 2 then
            col = uix.colors.red
        elseif i == 3 then
            col = uix.colors.orange
        elseif i == 4 then
            col = uix.colors.green
        elseif i == 5 then
            col = uix.colors.lime
        elseif i == 6 then
            col = uix.colors.blue
        elseif i == 7 then
            col = uix.colors.purple
        end
        self.window:fill(math.random(3, 8), math.random(3, self.window.sizeX - 2), 2, 1, col, 0, " ")
    end
end

local startGame = layout:createButton(math.round((rx / 2) - 7), math.round(ry / 2) - 1, 16, 3, uix.colors.lightGray, uix.black, "start game", true)
function startGame:onClick(_, nickname)
    ui:execute(gamePath, screen, nickname)
end

ui:loop()