local graphic = require("graphic")
local liked = require("liked")
local thread = require("thread")
local event = require("event")
local gui = require("gui")
local computer = require("computer")
local storage = require("storage")
local sound = require("sound")

local conf = storage.getConf({bestScore = 0})

--------------------------------

local screen = ...
local pal = liked.colors
local rx, ry = graphic.getResolution(screen)
local window = graphic.createWindow(screen, 1, 2, rx, ry - 1)
liked.regExit(screen, nil, true)
liked.regBar(screen, "Flapix")

local sizeX, sizeY = window.sizeX, window.sizeY

--------------------------------

local birdPosX = 20
local birdPosY = 4

local birdDelta = 0
local birdDeltaTarget

local score = 0
local pipes = {}

local function updateKey(state)
    birdDeltaTarget = state and -0.15 or 0.15
end
updateKey(false)

--------------------------------

local function addScore()
    score = score + 1
    if score > conf.bestScore then
        conf.bestScore = score
    end
    sound.beep(2000, 0.05)
end

local function drawPipe()
    for i, v in ipairs(pipes) do
        local x, y = math.round(v[1]), math.round(v[2])
        window:fill(x, 2, 2, y - 3, pal.green, 0, " ")
        window:fill(x, y + 2, 2, window.sizeY - y - 2, pal.green, 0, " ")
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
    gui.drawtext(screen, 2, 4, pal.white, "score     : " .. score)
    gui.drawtext(screen, 2, 5, pal.white, "best score: " .. conf.bestScore)
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

local oldPipeTime
local function addPipe()
    table.insert(pipes, {window.sizeX + 5, math.random(4, window.sizeY - 3)})
    oldPipeTime = computer.uptime()
end
addPipe()

thread.timer(1.5, function ()
    if computer.uptime() - oldPipeTime > 3 or math.random(1, 3) == 1 then
        addPipe()
    end
end, math.huge)

local tick = 0
while true do
    -- draw
    draw()

    -- process
    birdPosY = birdPosY + birdDelta
    birdDelta = birdDelta + ((birdDeltaTarget - birdDelta) * 0.03);
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
            table.remove(pipes, i)
        else
            pipe[1] = pipe[1] - 0.2
            if math.round(pipe[1]) == math.round(birdPosX) then
                if math.abs(math.round(pipe[2]) - math.round(birdPosY)) > 1 then
                    dieScreen()
                    return
                elseif not pipe[3] then
                    addScore()
                    pipe[3] = true
                end
            end
        end
    end

    -- delay
    if tick % 5 == 0 then
        os.sleep(0.05)
    end
    tick = tick + 1
end