local graphic = require("graphic")
local colors = require("gui_container").colors
local event = require("event")

local screen = ...
local orx, ory = graphic.getResolution(screen)

graphic.setResolution(screen, 80, 25)
local rx, ry = graphic.getResolution(screen)

local window = graphic.createWindow(screen, 1, 1, rx, ry)

------------------------------------

local function exit()
    graphic.setResolution(screen, orx, ory)
end

------------------------------------

local spaceshipPosX = 10
local spaceshipPosY = math.floor(ry / 2)
local entites = {{x = 10, y = 10, skin = "warnShip", warn = true}}
local running = true

local function draw()
    window:clear(colors.black)

    window:set(spaceshipPosX, spaceshipPosY + 1, colors.black, colors.yellow, "/")
    window:set(spaceshipPosX, spaceshipPosY - 1, colors.black, colors.yellow, "\\")
    window:set(spaceshipPosX, spaceshipPosY, colors.black, colors.red, ">")

    window:set(spaceshipPosX - 1, spaceshipPosY + 1, colors.lime, 0, " ")
    window:set(spaceshipPosX - 1, spaceshipPosY - 1, colors.lime, 0, " ")
    window:set(spaceshipPosX - 1, spaceshipPosY, colors.green, 0, " ")

    for k, v in pairs(entites) do
        if v.skin == "warnShip" then
            window:set(v.x, v.y - 1, colors.black, colors.lightGray, "/")
            window:set(v.x, v.y + 1, colors.black, colors.lightGray, "\\")
            window:set(v.x, v.y, colors.black, colors.white, "<")

            window:set(v.x + 1, v.y + 1, colors.lightGray, 0, " ")
            window:set(v.x + 1, v.y - 1, colors.lightGray, 0, " ")
            window:set(v.x + 1, v.y, colors.gray, 0, " ")
        end
        if v.x == spaceshipPosX and v.y == spaceshipPosY and v.warn then
            window:clear(colors.black)
            exit()
            running = false
            return
        end
    end
end
draw()

while running do
    local eventData = {event.pull()}
    local windowEventData = window:uploadEvent(eventData)
    if windowEventData[1] == "key_down" and (windowEventData[4] == 28 or (eventData[3] == 3 and eventData[4] == 46)) then
        exit()
        break
    end
    if windowEventData[1] == "touch" or windowEventData[1] == "drag" then
        spaceshipPosY = windowEventData[4]
        spaceshipPosX = windowEventData[3]
        draw()
    end
end