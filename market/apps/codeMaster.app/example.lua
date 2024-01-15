local num = tonumber(storage.getData()) or 1
local str = tostring(num)
storage.setData(tostring(num + 1))

for i = 1, #str do
    screen.set(i, 1, str:sub(i, i))
end

while true do
    sleep()
end