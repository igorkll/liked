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

local birdDelta = 0
local birdDeltaTarget

local score = 0
local pipes = {}

local function updateKey(state)
    birdDeltaTarget = state and -0.5 or 0.5
end
updateKey(false)

--------------------------------

local function drawPipe()
    for i, v in ipairs(pipes) do
        window:fill(v[1], 2, 2, 1, pal.green, 0, " ")
        window:fill(v[1], v[2] - 1, 2, 3, pal.lightBlue, 0, " ")
    end
end

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
    drawPipe()
    gui.drawtext(screen, 2, 2, pal.white, "score: " .. score)
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
    birdDelta = birdDelta + ((birdDeltaTarget - birdDelta) * 0.05);
    if birdPosY > window.sizeY - 1 then
        dieScreen(2)
        return
    elseif birdPosY < 2 then
        dieScreen(1)
        return
    end
    for i = #pipes, 1, -1 do
        local pipe = pipes[i]
        if pipe[1] < 1 then
            table.remove(pipe, i)
        else
            pipe[1] = pipe[1] - 1
        end
    end

    -- delay
    os.sleep(0)
end