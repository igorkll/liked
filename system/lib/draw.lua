local graphic = require("graphic")
local draw = {}

function draw:dot(x, y, color)
     
end

function draw:line(x, y, x2, y2, color)
    
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