local function drawText(x, y, str, color)
    for i = 1, #str do
        screen.set(x + (i - 1), y, str:sub(i, i), color)
    end
end

local function splash(str)
    str = tostring(str or "unknown error")
    screen.clear()
    drawText(1, 1, "ERROR")
    local rx, ry = screen.getSize()

    local xpos = 1
    local ypos = 2
    for i = 1, #str do
        local char = str:sub(i, i)
        if char == "\n" then
            xpos = 1
            ypos = ypos + 1
        else
            screen.set(xpos, ypos, char, 3)
            xpos = xpos + 1
            if xpos > rx then
                xpos = 1
                ypos = ypos + 1
            end
        end
    end
end

--------------------------------------------

device.beep(2000, 0.1)

local code, err = load(storage.getCode(), "=code")
if code then
    local ok, err = xpcall(code, debug.traceback)
    if not ok then
        splash(err)
    else
        device.shutdown()
    end
else
    splash(err)
end