local function drawText(x, y, str, color)
    for i = 1, #str do
        screen.set(x + (i - 1), y, str:sub(i, i), color)
    end
end

local function splash(str)
    screen.clear()
    drawText(1, 1, "ERROR")
    drawText(1, 2, str, 3)
end

splash("TEST TEST")
device.beep(2000, 0.05)
device.reboot()
device.beep(1000, 0.05)

while true do
    sleep()
end