local vec = require("vec")
local holo = ...

local deltatime = 0
local fireworks = {}
local debrises = {}

local function dot(firework, color)
    holo.set(math.round(firework.pos.x), math.round(firework.pos.y), math.round(firework.pos.z), color)
end

while true do
    local startTime = os.clock()
    for i = #fireworks, 1, -1 do
        local firework = fireworks[i]
        dot(firework, 0)
        firework.pos = firework.pos + (firework.vec * deltatime)
        if firework.pos.y >= firework.maxPos then
            table.remove(fireworks, i)
            for i = 1, math.random(15, 30) do
                table.insert(debrises, {
                    pos = firework.pos,
                    vec = vec.vec3((math.random() - 0.5) * 64, (math.random() - 0.5) * 64, (math.random() - 0.5) * 64),
                    maxtime = os.clock() + (math.random(1, 9) / 100),
                    color = math.random(1, colorsCount)
                })
            end
        else
            dot(firework, 1)
        end
    end
    for i = #debrises, 1, -1 do
        local debris = debrises[i]
        dot(debris, 0)
        debris.pos = debris.pos + (debris.vec * deltatime)
        if os.clock() >= debris.maxtime then
            table.remove(debrises, i)
        else
            dot(debris, debris.color)
        end
    end
    if math.random(0, 5) == 0 then
        table.insert(fireworks, {
            pos = vec.vec3(math.random(1, hx), 1, math.random(1, hz)),
            vec = vec.vec3((math.random() - 0.5) * 4, math.random(40, 70), (math.random() - 0.5) * 4),
            maxPos = math.random(hy / 3, hy - 2)
        })
    end
    deltatime = math.max(0.1, os.clock() - startTime)
    os.sleep(0.05)
end