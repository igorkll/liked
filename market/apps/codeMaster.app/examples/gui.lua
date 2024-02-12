local rx, ry = screen.getSize()
local red, green, blue, yellow = 0, 1, 2, 3

function math.round(val)
    return math.floor(val + 0.5)
end

local function drawtext(x, y, text, color)
    for i = 1, #text do
        screen.set(x + (i - 1), y, text:sub(i, i), color)
    end
end

local function centertext(x, y, text, color)
    drawtext(x - (math.round(#text / 2) - 1), y, text, color)
end

local states = {}
states[keyboard.isAction] = keyboard.isAction()
states[keyboard.isUp] = keyboard.isUp()
states[keyboard.isDown] = keyboard.isDown()
states[keyboard.isLeft] = keyboard.isLeft()
states[keyboard.isRight] = keyboard.isRight()

local function isPress(func)
    local state = func()
    local oldstate = states[func]
    states[func] = state
    return state and not oldstate
end

local function wait(func)
    while not isPress(func) do
        sleep()
    end
end

local function splash(str)
    screen.clear()
    centertext(rx / 2, ry / 2, str, green)
    centertext(rx / 2, ry - 1, "Press Action To Continue", red)
    wait(keyboard.isAction)
end

local function menu(title, actions)
    local pos = 1

    screen.clear()
    centertext(rx / 2, 2, title, yellow)
    for i, action in ipairs(actions) do
        centertext(rx / 2, 3 + i, action[1], red)
    end

    local oldPos
    local function drawCustomPos(p)
        if oldPos == p then return end
        if oldPos then
            drawtext(2, 3 + oldPos, "   ", yellow)
        end
        drawtext(2, 3 + p, ">>>", yellow)
        oldPos = p
    end
    
    while true do
        drawCustomPos(pos)

        if isPress(keyboard.isUp) then
            pos = pos - 1
            if pos < 1 then pos = 1 end
        elseif isPress(keyboard.isDown) then
            pos = pos + 1
            if pos > #actions then pos = #actions end
        elseif isPress(keyboard.isAction) then
            actions[pos][2]()
        end

        sleep(0.1)
    end
end

-------------------------------- example

splash("test")
menu("test menu", {
    {
        "reboot",
        device.reboot
    },
    {
        "shutdown",
        device.shutdown
    }
})