local vec = require("vec")
local holo = ...

local function drawCircle_draw(y, x, z, color, rand)
    if not rand or math.random(0, rand) == 0 then
        holo.set(x, y, z, col(color))
    end
end

local function drawCircle_putpixel(w, cx, cy, x, y, color, rand)
    local posDX_x = cx + x
    local negDX_x = cx - x
    local posDX_y = cx + y
    local negDX_y = cx - y

    local posDY_y = cy + y
    local negDY_y = cy - y
    local posDY_x = cy + x
    local negDY_x = cy - x

    drawCircle_draw(w, posDX_x, posDY_y, color, rand)
    drawCircle_draw(w, negDX_x, posDY_y, color, rand)
    drawCircle_draw(w, posDX_x, negDY_y, color, rand)
    drawCircle_draw(w, negDX_x, negDY_y, color, rand)
    drawCircle_draw(w, posDX_y, posDY_x, color, rand)
    drawCircle_draw(w, negDX_y, posDY_x, color, rand)
    drawCircle_draw(w, posDX_y, negDY_x, color, rand)
    drawCircle_draw(w, negDX_y, negDY_x, color, rand)
end

local function drawCircle(x, w, y, r, color, rand)
    local lx = 0
    local ly = r
    local d = 3 - 2 * r

    drawCircle_putpixel(w, x, y, lx, ly, color, rand)
    while ly >= lx do
        lx = lx + 1

        if d > 0 then
            ly = ly - 1
            d = d + 4 * (lx - ly) + 10
        else
            d = d + 4 * lx + 6
        end

        drawCircle_putpixel(w, x, y, lx, ly, color, rand)
    end
end


--------------------------------------------------

local function cone(add, len, col, rand, randcol)
    for i = 0.5, len, 0.1 do
        if rand then
            drawCircle(hx / 2, hy - i - 0 - add, hz / 2, i + 1, randcol, rand)
        end
        drawCircle(hx / 2, hy - i - 0 - add, hz / 2, i, col)
        drawCircle(hx / 2, hy - i - 1 - add, hz / 2, i, col)
    end
end

local function get(pos)
    return holo.get(math.round(pos.x), math.round(pos.y), math.round(pos.z))
end

local function dot(pos, color)
    holo.set(math.round(pos.x), math.round(pos.y), math.round(pos.z), col(color))
end

local deltatime = 0
local fireworks = {}

cone(0, 10, 2, colorsCount > 1 and 300, 1)
cone(10, 15, 2, colorsCount > 1 and 250, 1)
cone(20, 10, 2)

while true do
    local startTime = os.clock()
    for i = #fireworks, 1, -1 do
        local firework = fireworks[i]

        firework.pos = firework.pos + (firework.vec * deltatime)
        if firework.pos.x < 1 then firework.pos.x = 1 end
        if firework.pos.z < 1 then firework.pos.z = 1 end
        if firework.pos.x > hx then firework.pos.x = hx end
        if firework.pos.z > hz then firework.pos.z = hz end

        if firework.pos.y <= 1 then
            table.remove(fireworks, i)
            firework.pos.y = 1
        end
        if firework.oldColor then
            if firework.oldColor == 3 then
                dot(firework.oldPos, 0)
            else
                dot(firework.oldPos, firework.oldColor)
            end
        end
        firework.oldColor = get(firework.pos)
        firework.oldPos = firework.pos()
        dot(firework.pos, 3)
    end

    if true or math.random(0, 2) == 0 then
        table.insert(fireworks, {
            pos = vec.vec3(math.random(1, hx), hy, math.random(1, hz)),
            vec = vec.vec3((math.random() - 0.5) * 4, -math.random(10, 20), (math.random() - 0.5) * 4)
        })
    end

    deltatime = math.max(0.1, os.clock() - startTime)
    os.sleep(0.05)
end