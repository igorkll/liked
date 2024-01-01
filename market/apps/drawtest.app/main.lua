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

local cx, cy = 15, 15

thread.listen(nil, function (...)
    local localEventData = render:touchscreen({...})
    if localEventData and (localEventData[1] == "touch" or localEventData[1] == "drag") then
        cx, cy = localEventData[3], localEventData[4]
    end
end)

while true do
    render:clear()
    render:setColorMask(hueMash)
    render:circle(cx, cy, 10)
    render:setColorMask()
    render:drawCircle(cx, cy, 10, 0xff0000)
    render:update()
    os.sleep(0.2)
end