local uix = require("uix")
local registry = require("registry")
local system = require("system")
local paths = require("paths")
local sound = require("sound")
local fs = require("filesystem")
local apps = require("apps")

local screen = ...
local ui = uix.manager(screen)
local rx, ry = ui:zoneSize()

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
        code = assert(fs.readFile(system.getResourcePath("example.lua"))),
        data = ""
    })
    computerThread = nil
    deviceScreen:clear(uix.colors.black)
    ui:select(gameLayout)
end

local function createSandbox()
    local sandbox
    sandbox = {
        math = table.deepclone(math),
        table = table.deepclone(table),
        string = table.deepclone(string),
        bit32 = table.deepclone(bit32),

        load = function (chunk, chunkname, mode, env)
            return load(chunk, chunkname, "t", env or sandbox)
        end,

        screen = {
            clear = function ()
                deviceScreen:clear(uix.colors.black)
            end,
            set = function (x, y, char, color)
                local lcolor = uix.colors.red
                if color == 1 then
                    lcolor = uix.colors.green
                elseif color == 2 then
                    lcolor = uix.colors.blue
                elseif color == 3 then
                    lcolor = uix.colors.yellow
                end

                if #char ~= 1 then error("unsupported string length", 2) end
                local byte = string.byte(char)
                if byte < 32 or byte > 126 then
                    char = "?"
                end

                deviceScreen:set(x, y, uix.colors.black, lcolor, char)
            end,
            getSize = function ()
                return deviceScreen.sx, deviceScreen.sy
            end
        }
    }
    return sandbox
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

local rusDocumentationButton = menuLayout:createButton(rx - 20, ry - 3, 20, 1, startButtonsBack, startButtonsFore, "rus documentation", true)
function rusDocumentationButton:onClick()
    ui:fullStop()
    apps.execute("edit", screen, nil, system.getResourcePath("documentation_rus.txt"), true)
    ui:fullStart()
    ui:draw()
end

local engDocumentationButton = menuLayout:createButton(rx - 20, ry - 1, 20, 1, startButtonsBack, startButtonsFore, "eng documentation", true)
function engDocumentationButton:onClick()
    ui:fullStop()
    apps.execute("edit", screen, nil, system.getResourcePath("documentation_eng.txt"), true)
    ui:fullStart()
    ui:draw()
end

-------------------------------- game

gameLayout = ui:create("Code Master", uix.colors.white, uix.styles[2])
gameLayout:setReturnLayout(exitFromGame)

deviceScreenSize = ry - 4
gameLayout:createPlane(5, 3, rx - 8, deviceScreenSize, uix.colors.lightGray)
deviceScreen = gameLayout:createCanvas(5, 3, deviceScreenSize * 2, deviceScreenSize)

--------------------------------

ui:loop()