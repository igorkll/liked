local graphic = require("graphic")
local liked = require("liked")
local thread = require("thread")
local event = require("event")
local gui = require("gui")

--------------------------------

local screen = ...
local pal = liked.colors
local rx, ry = graphic.getResolution(screen)
local window = graphic.createWindow(screen, 1, 2, rx, ry - 1)
liked.regExit(screen, nil, true)
liked.regBar(screen, "Flapix")

local sizeX, sizeY = window.sizeX, window.sizeY

--------------------------------

local birdPosX = 15
local birdPosY = 4

local birdDelta = 0.1
local birdDeltaTarget

local score = 0

local function updateKey(state)
    birdDeltaTarget = state and -3 or 3
end
updateKey(false)

--------------------------------

local function draw(altDraw)
    local y = math.round(birdPosY)
    if altDraw == 1 then
        y = 2
    elseif altDraw == 2 then
        y = window.sizeY - 1
    end

    window:clear(pal.brown)
    window:fill(1, 2, window.sizeX, window.sizeY - 2, pal.lightBlue, 0, " ")
    window:fill(math.round(birdPosX), y, 2, 1, pal.yellow, 0, " ")
    window:set(2, 2, pal.lightBlue, pal.white, "score: " .. score)
end

local function dieScreen(altDraw)
    draw(altDraw)
    gui.warn(screen, nil, nil, "you're dead.\nscore: " .. score)
end

thread.create(function ()
    while true do
        local eventData = {event.pull()}
        local windowEventData = window:uploadEvent(eventData)
        if eventData[1] == "touch" or eventData[1] == "key_down" then
            updateKey(true)
        elseif eventData[1] == "drop" or eventData[1] == "key_up" then
            updateKey(false)
        end
    end
end):resume()

while true do
    -- draw
    draw()

    -- process
    birdPosY = birdPosY + birdDelta
    birdDelta = birdDelta + ((birdDeltaTarget - birdDelta) * 0.2);
    if birdPosY >= window.sizeY then
        dieScreen(2)
        return
    elseif birdPosY <= 1 then
        dieScreen(1)
        return
    end

    -- delay
    os.sleep(0.05)
end