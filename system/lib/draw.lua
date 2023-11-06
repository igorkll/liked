local graphic = require("graphic")
local draw = {}

function draw:dot(x, y, color)
    if self.mode == "full" then
        self.window:set(x, y, color, 0, " ")
    end
end

function draw:line(x0, y0, x1, y1, color)
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

function draw.create(window, mode)
    if type(window) == "string" then
        window = graphic.create(window, 1, 1, graphic.getResolution(window))
    end

    return setmetatable(
        {
            window = window,
            mode = mode or "full"
        },
        {
            __index = draw
        }
    )
end

draw.unloadable = true
return draw