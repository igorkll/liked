local draw = require("draw")
local colors = require("colors")
local liked = require("liked")
local thread = require("thread")

local screen = ...
local render = draw.create(liked.applicationWindow(screen, "Shooting"), draw.modes.semi)
local rx, ry = render:size()
liked.regExit(screen, nil, true)

local cx, cy = rx / 3, ry / 2
local mr = (ry / 2) - 5

local function redraw()
    render:clear(draw.colors.lightGray)
    local state = false
    for r = mr, 3, -3 do
        render:circle(cx, cy, r, state and draw.colors.gray or draw.colors.white)
        state = not state
    end
end
redraw()

while true do
    os.sleep(0.1)
end