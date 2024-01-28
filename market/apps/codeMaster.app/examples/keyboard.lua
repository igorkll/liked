local rx, ry = screen.getSize()

while true do
    screen.clear()
    if keyboard.isUp() then
        screen.set(3, 2, "U", 1)
    else
        screen.set(3, 2, "U")
    end
    if keyboard.isAction() then
        screen.set(3, 3, "A", 1)
    else
        screen.set(3, 3, "A")
    end
    if keyboard.isDown() then
        screen.set(3, 4, "D", 1)
    else
        screen.set(3, 4, "D")
    end

    if keyboard.isLeft() then
        screen.set(2, 3, "L", 1)
    else
        screen.set(2, 3, "L")
    end
    if keyboard.isRight() then
        screen.set(4, 3, "R", 1)
    else
        screen.set(4, 3, "R")
    end

    local str = keyboard.get()
    for i = 1, #str do
        screen.set(i, ry, str:sub(i, i), 3)
    end

    sleep(0.1)
end