local draw = require("draw")
local colors = require("colors")
local liked = require("liked")
local thread = require("thread")

local screen = ...
local render = draw.create(screen, draw.modes.semi)
local rx, ry = render:size()

liked.regExit(screen)


local function hueMash(x, y)
    local value = ((x / rx) + (y / ry)) / 2
    return colors.blend(colors.hsvToRgb(value * 255, 255, 255))
end

local cx, cy = 5, 5
local count = 0
local pixels = {}

thread.listen(nil, function (...)
    local eventData = render:touchscreen({...})
    if eventData and (eventData[1] == "touch" or eventData[1] == "drag") then
        table.insert(pixels, {eventData[3], eventData[4]})
    end
end)

while true do
    render:clear()
    render:setColorMask(hueMash)
    render:line(2, 2, rx - 1, ry - 1)
    render:circle(cx, cy, 5)
    render:setColorMask()
    render:drawCircle(cx, cy, 5, 0xff0000)
    for i, v in ipairs(pixels) do
        render:dot(v[1], v[2], 0xffffff)
    end
    render:update()
    os.sleep(0.1)

    if cx > rx then
        cx = 1
    else
        cx = cx + 1
    end
    if cy > ry then
        cy = 1
    else
        cy = cy + 1
    end
    count = count + 1
end