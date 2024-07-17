local graphic = require("graphic")
local gui_container = require("gui_container")

local draw = {modes = {}, colors = gui_container.colors}
draw.modes.box = 0
draw.modes.full = 1
draw.modes.semi = 2
draw.modes.braille = 3

local rep = string.rep

-------------------------------- base

local function map(...)
    return math.ceil(math.map(...))
end

function draw:toRealPos(x, y) --конвертирует позицию с холста в позицию opencomputers
    local sx, sy = self:size()
    local rx, ry = self.window.sizeX, self.window.sizeY
    return map(x, 1, sx, 1, rx), map(y, 1, sy, 1, ry)
end

function draw:toFakePos(x, y) --конвертирует позицию opencomputers в позицию холста
    local sx, sy = self:size()
    local rx, ry = self.window.sizeX, self.window.sizeY
    return map(x, 1, rx, 1, sx), map(y, 1, ry, 1, sy)
end

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
    if self.mask then
        color = self.mask(x, y, color, table.unpack(self.maskArgs)) or color
    end

    color = color or 0xffffff
    local offsetX, offsetY = self.window.x - 2, self.window.y - 2
    local gpu, index
    local setX, setY, setB, setF, setC, setI
    local chars, foregrounds, backgrounds, width, height
    if self.mode == draw.modes.box then
        setX, setY, setB, setF, setC, setI = ((x - 1) * 2) + 1, y, color, 0, " ", 2
    elseif self.mode == draw.modes.full then
        setX, setY, setB, setF, setC, setI = x, y, color, 0, " ", 1
    elseif self.mode == draw.modes.semi then
        local realY = ((y - 1) // 2) + 1

        gpu = graphic.findGpu(self.window.screen)
        local _, fore, back
        if gpu and gpu.getSoftwareBuffers then
            chars, foregrounds, backgrounds, width, height = gpu.getSoftwareBuffers()
            index = offsetX + x + 1 + ((offsetY + realY) * width)
            fore, back = foregrounds[index], backgrounds[index]
        else
            _, _, fore, back = pcall(self.window.get, self.window, x, realY)
        end
        
        if fore then
            if y % 2 == 0 then
                fore = color
            else
                back = color
            end
            setX, setY, setB, setF, setC, setI = x, realY, back, fore, "▄", 1
        end
    end

    if setX then
        gpu = gpu or graphic.findGpu(self.window.screen)
        if gpu and gpu.getSoftwareBuffers then
            if not chars then
                chars, foregrounds, backgrounds, width, height = gpu.getSoftwareBuffers()
            end
            index = offsetX + setX + 1 + ((offsetY + setY) * width)
            for i = 1, setI do
                chars[index] = setC
                foregrounds[index] = setF
                backgrounds[index] = setB
                index = index + 1
            end
        else
            self.window:set(setX, setY, setB, setF, rep(setC, setI))
        end
    end
end

function draw:update()
    graphic.update(self.window.screen)
end

-------------------------------- graphic

function draw:line(x0, y0, x1, y1, color)
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
    color = color or 0xffffff

    for ix = x, x + (sx - 1) do
        for iy = y, y + (sy - 1) do
            if ix == x or iy == y or ix == (x + (sx - 1)) or iy == (y + (sy - 1)) then
                self:dot(ix, iy, color)
            end
        end
    end
end

local function quadInCircle(qx, qy, qs, cx, cy, cr)
	local lx = qx - cx
	local ly = qy - cy

	local cr_sq = cr*cr

	local pointIn = function (dx, dy)
		return dx*dx + dy*dy <= cr_sq
	end

	return pointIn(lx, ly) and pointIn(lx + qs, ly) and pointIn(lx, ly + qs) and pointIn(lx + qs, ly + qs)
end

function draw:circle(x, y, r, color)
    x = math.round(x) + 0.5
    y = math.round(y) + 0.5
    r = math.round(r) + 0.5

    local rx, ry = self:size()
    local px, py
    for ix = math.max(-r, -x + 1), math.min(r, rx - x) do
        px = x + ix
        for iy = math.max(-r, -y + 1), math.min(r, ry - y) do
            py = y + iy
            if quadInCircle(px, py, 1, x, y, r) then
                self:dot(px, py, color)
            end
        end
    end
end

local function drawCircle_putpixel(self, cx, cy, x, y, color)
    local posDX_x = cx + x
    local negDX_x = cx - x
    local posDX_y = cx + y
    local negDX_y = cx - y

    local posDY_y = cy + y
    local negDY_y = cy - y
    local posDY_x = cy + x
    local negDY_x = cy - x

    self:dot(posDX_x, posDY_y, color)
    self:dot(negDX_x, posDY_y, color)
    self:dot(posDX_x, negDY_y, color)
    self:dot(negDX_x, negDY_y, color)
    self:dot(posDX_y, posDY_x, color)
    self:dot(negDX_y, posDY_x, color)
    self:dot(posDX_y, negDY_x, color)
    self:dot(negDX_y, negDY_x, color)
end

function draw:drawCircle(x, y, r, color)
    local lx = 0
    local ly = r
    local d = 3 - 2 * r

    drawCircle_putpixel(self, x, y, lx, ly, color)
    while ly >= lx do
        lx = lx + 1

        if d > 0 then
            ly = ly - 1
            d = d + 4 * (lx - ly) + 10
        else
            d = d + 4 * lx + 6
        end

        drawCircle_putpixel(self, x, y, lx, ly, color)
    end
end

function draw:clear(color)
    if self.mask then
        local sx, sy = self:size()
        self:fill(1, 1, sx, sy, color or 0x000000)
    else
        self.window:clear(color or 0x000000)
    end
end

-------------------------------- advanced

function draw:setColorMask(mask, ...)
    self.mask = mask
    self.maskArgs = {...}
end

function draw:touchscreen(eventData)
    if eventData[2] == self.window.screen and (eventData[1] == "touch" or eventData[1] == "drag" or eventData[1] == "drop" or eventData[1] == "scroll") then
        if not eventData.windowEventData then
            eventData = self.window:uploadEvent(eventData)
        end

        if eventData and eventData[3] then
            eventData[3], eventData[4] = self:toFakePos(eventData[3], eventData[4])
            return eventData
        end
    end
end

-------------------------------- main

function draw.create(window, mode)
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
            mode = mode
        },
        {
            __index = draw
        }
    )
end

draw.unloadable = true
return draw