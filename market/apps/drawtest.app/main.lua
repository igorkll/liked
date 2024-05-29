local draw = require("draw")
local colors = require("colors")
local liked = require("liked")
local thread = require("thread")
local adv = require("adv")

local screen = ...
local render = draw.create(screen, draw.modes.semi)
local rx, ry = render:size()

liked.regExit(screen)


local function hueMash(x, y, _, px, py, cr)
    return colors.blend(colors.hsvToRgb(adv.dist2(x, y, px, py) * cr * 2, 255, 255))
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
    render:setColorMask(hueMash, cx + 1, cy + 1, 10)
    render:circle(cx, cy, 10)
    render:setColorMask()
    render:drawCircle(cx, cy, 10, 0xff0000)
    render:rect(2, 2, 10, 10, 0x00ffff)
    render:fill(15, 15, 10, 10, 0xff00ff)
    render:update()
    os.sleep(0.1)
end