local uix = require("uix")
local registry = require("registry")
local system = require("system")
local paths = require("paths")
local sound = require("sound")
local fs = require("filesystem")

local screen = ...
local ui = uix.manager(screen)

-------------------------------- vars

local gamesavePath
local gamesave
local computerThread

local function exitFromGame()
    gamesavePath = nil
    gamesave = nil
    computerThread = nil
    ui:select(menuLayout)
end

local function startGame(num)
    gamesavePath = system.getResourcePath(paths.concat("saves", tostring(math.round(num))))
    gamesave = registry.new(paths.concat(gamesavePath, "settings.dat"), {
        code = assert(fs.readFile(system.getResourcePath("example.lua")))
    })
    computerThread = nil
    ui:select(gameLayout)
end

-------------------------------- menu

startButtonsBack, startButtonsFore = uix.colors.lightGray, uix.colors.black

menuLayout = ui:create("Code Master", uix.colors.white, uix.styles[2])
menuLayout:createImage(2, 2, "logo.t2p")
for i = 0, 5 do
    local start = menuLayout:createButton(2 + ((i // 2) * 17), 2 + 8 + ((i % 2) * 6), 16, 5, startButtonsBack, startButtonsFore, "save slot " .. (i + 1), true)
    function start:onClick()
        startGame(i)
    end
end

-------------------------------- game

gameLayout = ui:create("Code Master", uix.colors.white, uix.styles[2])
gameLayout:setReturnLayout(exitFromGame)

--------------------------------

ui:loop()