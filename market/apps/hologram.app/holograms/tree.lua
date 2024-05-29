local holo = ...

local function box(x, y, z, color)
    local size = 8
    for ix = x * size, (x * size) + size do
        for iy = y * size, (y * size) + size do
            for iz = z * size, (z * size) + size do
                holo.set(ix + 1, iy + 1, iz + 1, col(color))
            end
        end
    end
end

box(2.5, 0, 2.5, 2)
box(2.5, 1, 2.5, 2)
box(2.5, 2, 2.5, 2)

for ix = 2, 3 do
    for iy = 2, 3 do
        box(ix, 3, iy, 1)
    end
end

box(1.5, 2, 1.5, 1)
box(1.5, 2, 2.5, 1)
box(2.5, 2, 1.5, 1)

box(1.5, 2, 3.5, 1)
box(3.5, 2, 1.5, 1)

box(3.5, 2, 3.5, 1)
box(2.5, 2, 3.5, 1)
box(3.5, 2, 2.5, 1)