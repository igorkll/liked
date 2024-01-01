local graphic = require("graphic")
local draw = {modes = {}}
draw.modes.box = 0
draw.modes.full = 1
draw.modes.semi = 2
draw.modes.braille = 3

-------------------------------- base

function draw:size()
    local rx, ry = self.window.sizeX, self.window.sizeY
    if self.mode == draw.modes.box then
        return rx / 2, ry
    elseif self.mode == draw.modes.full then
        return rx, ry
    elseif self.mode == draw.modes.semi then
        return rx, ry * 2
    elseif self.mode == draw.modes.braille then
        return rx * 2, ry * 4
    end
end

function draw:dot(x, y, color)
    x = self:normalizePos(x)
    y = self:normalizePos(y)

    if self.mask then
        color = self.mask(x, y, color) or color
    end

    color = color or 0xffffff

    if self.mode == draw.modes.box then
        self.window:set(((x - 1) * 2) + 1, y, color, 0, "  ")
    elseif self.mode == draw.modes.full then
        self.window:set(x, y, color, 0, " ")
    end
end

function draw:update()
    graphic.update(self.window.screen)
end

-------------------------------- graphic

function draw:line(x0, y0, x1, y1, color)
    x0 = self:normalizePos(x0)
    y0 = self:normalizePos(y0)
    x1 = self:normalizePos(x1)
    y1 = self:normalizePos(y1)
    color = color or 0xffffff

    local sx, sy, e2, err;
    local dx = math.abs(x1 - x0);
    local dy = math.abs(y1 - y0);
    sx = (x0 < x1) and 1 or -1;
    sy = (y0 < y1) and 1 or -1;
    err = dx - dy;
    while true do
        self:dot(x0, y0, color)
        if (x0 == x1 and y0 == y1) then
            return
        end
        e2 = err<<1;
        if e2 > -dy then 
            err = err - dy; 
            x0 = x0 + sx; 
        end
        if e2 < dx then
            err = err + dx
            y0 = y0 + sy
        end
    end
end

function draw:fill(x, y, sx, sy, color)
    x = self:normalizePos(y)
    x = self:normalizePos(y)
    sx = math.round(sx)
    sy = math.round(sy)
    color = color or 0xffffff

    if self.mode == draw.modes.box and not self.mask then
        self.window:fill(x, y, sx * 2, sy, color, 0, " ")
    elseif self.mode == draw.modes.full and not self.mask then
        self.window:fill(x, y, sx, sy, color, 0, " ")
    else
        for ix = x, x + (sx - 1) do
            for iy = y, y + (sy - 1) do
                self:dot(ix, iy, color)
            end
        end
    end
end

function draw:rect(x, y, sx, sy, color)
    x = self:normalizePos(y)
    x = self:normalizePos(y)
    sx = math.round(sx)
    sy = math.round(sy)
    color = color or 0xffffff

    for ix = x, x + (sx - 1) do
        for iy = y, y + (sy - 1) do
            if ix == x or iy == y or ix == (x + (sx - 1)) or iy == (y + (sy - 1)) then
                self:dot(ix, iy, color)
            end
        end
    end
end

function draw:clear(color)
    self.window:clear(color or 0x000000)
end

-------------------------------- advanced

function draw:setColorMask(mask)
    self.mask = mask
end

-------------------------------- internal

function draw:normalizePos(pos)
    return math.round(pos) + self.goffset
end

-------------------------------- main

function draw.create(window, mode, fromZero)
    mode = mode or draw.modes.full
    if mode < draw.modes.box or mode > draw.modes.braille then
        error("the wrong mode", 2)
    end

    if type(window) == "string" then
        window = graphic.createWindow(window, 1, 1, graphic.getResolution(window))
    end

    return setmetatable(
        {
            window = window,
            mode = mode,
            goffset = fromZero and 1 or 0
        },
        {
            __index = draw
        }
    )
end

draw.unloadable = true
return draw