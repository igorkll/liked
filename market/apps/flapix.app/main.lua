local graphic = require("graphic")
local liked = require("liked")
local thread = require("thread")
local event = require("event")

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

local function updateKey(state)
    birdDeltaTarget = state and -5 or 5
end
updateKey(false)

--------------------------------

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
    window:clear(pal.lightBlue)
    window:fill(math.round(birdPosX), math.round(birdPosY), 2, 1, pal.yellow, pal.yellow, " ")

    -- process
    birdPosY = birdPosY + birdDelta
    birdDelta = birdDelta + ((birdDeltaTarget - birdDelta) * 0.1);

    -- delay
    os.sleep(0.05)
end