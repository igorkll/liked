local thread = require("thread")
local holo = ...

local function shot(x, z)
    local y = 1
    local maxPos = math.random(hy / 2, (hy / 3) * 2)
    thread.create(function ()
        local wait = math.random(1, 10) / 30
        while true do
            holo.set(x, y - 1, z, 0)
            holo.set(x, y, z, 1)
            os.sleep(wait)
            y = y + 1
            if y >= maxPos then
                while true do
                    
                end
                break
            end
        end
    end)
end

while true do
    shot(math.random(1, hx), math.random(1, hz))
    os.sleep(math.random(1, 10) / 10)
end