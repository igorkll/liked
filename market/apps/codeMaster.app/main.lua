local uix = require("uix")
local registry = require("registry")
local system = require("system")
local paths = require("paths")
local sound = require("sound")
local fs = require("filesystem")
local apps = require("apps")
local thread = require("thread")

local screen = ...
local ui = uix.manager(screen)
local rx, ry = ui:zoneSize()

-------------------------------- vars

local dataLimit = 4 * 1024
local codeLimit = 16 * 1024

local gamesavePath
local gamesave
local computerThread

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

        sleep = function (time)
            checkArg(1, time, "number")
            os.sleep(time or 0.05)
        end,

        device = {
            beep = function (freq, delay)
                sound.beep(freq, delay, true)
            end
        },

        storage = {
            getData = function()
                return gamesave.data
            end,
            setData = function(data)
                checkArg(1, data, "string")
                if #data > dataLimit then
                    error("the maximum amount of data is 4KB", 2)
                end
                gamesave.data = data
            end,

            getCode = function()
                return gamesave.code
            end,
            setCode = function(code)
                checkArg(1, code, "string")
                if #code > codeLimit then
                    error("the maximum amount of data is 16KB", 2)
                end
                gamesave.code = code
            end,
        },

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

local function exitFromGame()
    deviceScreen:clear(uix.colors.black)
    gamesavePath = nil
    gamesave = nil
    if computerThread then
        computerThread:kill()
    end
    computerThread = nil
    ui:select(menuLayout)
end

local function startGame(num)
    gamesavePath = system.getResourcePath(paths.concat("saves", tostring(math.round(num))))
    gamesave = registry.new(paths.concat(gamesavePath, "settings.dat"), {
        bios = assert(fs.readFile(system.getResourcePath("bios.lua"))),
        code = assert(fs.readFile(system.getResourcePath("example.lua"))),
        data = ""
    })

    ui:select(gameLayout)
end

local function powerOff()
    if computerThread then
        computerThread:kill()
        computerThread = nil
    end

    deviceScreen:clear(uix.colors.black)
end

local function powerOn()
    local code = load(gamesave.bios, "=bios", "t", createSandbox()) --ошибки в BIOS нечем не будут обработаны
    if code then
        computerThread = thread.create(code)
        computerThread:resume()
    end
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

gameLayout:createPlane(5, 3, rx - 8, ry - 4, uix.colors.lightGray)
deviceScreen = gameLayout:createCanvas(7, 4, (ry - 6) * 2, ry - 6)

powerButton = gameLayout:createButton(rx - 10, 3, 7, 3, uix.colors.red, uix.colors.white, "POWER")
powerButton.back2 = uix.colors.brown
powerButton.fore2 = uix.colors.white
powerButton.toggle = true
function powerButton:onSwitch()
    if self.state then
        powerOn()
    else
        powerOff()
    end
end

function gameLayout:onSelect()
    deviceScreen:clear(uix.colors.black)
    powerButton.state = false
end

--------------------------------

ui:loop()