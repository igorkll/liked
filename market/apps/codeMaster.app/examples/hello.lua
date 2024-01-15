local str = "hello, world!"
for i = 1, #str do
    screen.set(i, 1, str:sub(i, i))
end

while true do
    sleep()
end