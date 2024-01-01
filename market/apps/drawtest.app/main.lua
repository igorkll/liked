local draw = require("draw")
local colors = require("colors")

local screen = ...
local render = draw.create(screen, draw.modes.box)
local rx, ry = render:size()

local function hueMash(x, y)
    local value = ((x / rx) + (y / ry)) / 2
    return colors.blend(colors.hsvToRgb(value * 255, 255, 255))
end

while true do
    render:clear()
    render:setColorMask(hueMash)
    render:line(2, 2, rx - 1, ry - 1)
    render:setColorMask()
    render:update()
    os.sleep(1)
end