local draw = require("draw")
local colors = require("colors")
local liked = require("liked")
local thread = require("thread")

local screen = ...
local render = draw.create(liked.applicationWindow(screen, "Shooting"), draw.modes.semi)
local rx, ry = render:size()
liked.regExit(screen, nil, true)

local mr = math.round(ry / 2) - 1
local cand = 2
local cx, cy = mr + 2, ry / 2

local function redraw()
    render:clear(draw.colors.lightGray)
    local state = false
    local skip = math.huge
    for r = mr, cand, -1 do
        if skip >= 2 or r == cand then
            local color = state and draw.colors.gray or draw.colors.white
            if r == cand then
                color = draw.colors.red
            end
            render:circle(cx, cy, r, color)
            state = not state
            skip = 0
        end
        skip = skip + 1
    end
end
redraw()

while true do
    os.sleep(0.1)
end