local vec = require("vec")
local holo = ...
local buffer = {}
for ix = 1, hx do
    buffer[ix] = {}
    for iy = 1, hy do
        buffer[ix][iy] = {}
        for iz = 1, hz do
            buffer[ix][iy][iz] = 0
        end
    end
end

local function drawCircle_draw(y, x, z, color)
    color = col(color)
    holo.set(x, y, z, color)
    buffer[x][y][z] = color
end

local function drawCircle_putpixel(w, cx, cy, x, y, color)
    local posDX_x = cx + x
    local negDX_x = cx - x
    local posDX_y = cx + y
    local negDX_y = cx - y

    local posDY_y = cy + y
    local negDY_y = cy - y
    local posDY_x = cy + x
    local negDY_x = cy - x

    drawCircle_draw(w, posDX_x, posDY_y, color)
    drawCircle_draw(w, negDX_x, posDY_y, color)
    drawCircle_draw(w, posDX_x, negDY_y, color)
    drawCircle_draw(w, negDX_x, negDY_y, color)
    drawCircle_draw(w, posDX_y, posDY_x, color)
    drawCircle_draw(w, negDX_y, posDY_x, color)
    drawCircle_draw(w, posDX_y, negDY_x, color)
    drawCircle_draw(w, negDX_y, negDY_x, color)
end

local function drawCircle(x, w, y, r, color)
    local lx = 0
    local ly = r
    local d = 3 - 2 * r

    drawCircle_putpixel(w, x, y, lx, ly, color)
    while ly >= lx do
        lx = lx + 1

        if d > 0 then
            ly = ly - 1
            d = d + 4 * (lx - ly) + 10
        else
            d = d + 4 * lx + 6
        end

        drawCircle_putpixel(w, x, y, lx, ly, color)
    end
end


--------------------------------------------------

local function cone(add, len, col)
    for i = 0.5, len, 0.1 do
        drawCircle(hx / 2, hy - i - 0 - add, hz / 2, i, col)
        drawCircle(hx / 2, hy - i - 1 - add, hz / 2, i, col)
    end
end

local function dot(firework, color)
    holo.set(math.round(firework.pos.x), math.round(firework.pos.y), math.round(firework.pos.z), color)
end

local deltatime = 0
local fireworks = {}

cone(0, 10, 1)
cone(10, 15, 1)
cone(20, 10, 2)

while true do
    local startTime = os.clock()
    for i = #fireworks, 1, -1 do
        local firework = fireworks[i]
        dot(firework, buffer[math.round(firework.pos.x)][math.round(firework.pos.y)][math.round(firework.pos.z)])
        firework.pos = firework.pos + (firework.vec * deltatime)
        if firework.pos.y >= firework.maxPos then
            table.remove(fireworks, i)
        else
            dot(firework, 3)
        end
    end
    if math.random(0, 5) == 0 then
        table.insert(fireworks, {
            pos = vec.vec3(math.random(1, hx), 1, math.random(1, hz)),
            vec = vec.vec3((math.random() - 0.5) * 4, math.random(20, 50), (math.random() - 0.5) * 4),
            maxPos = math.random(hy / 2, hy - 2)
        })
    end
    deltatime = math.max(0.1, os.clock() - startTime)
    os.sleep(0.05)
end