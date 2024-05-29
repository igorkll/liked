local rx, ry = screen.getSize()

while true do
    screen.set(math.random(1, rx), math.random(1, ry), "%", math.random(0, 3))
end