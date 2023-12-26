local host = require("host")
local graphic = require("graphic")
local colors = require("gui_container").colors
local thread = require("thread")
local screen = ...

local rx, ry = graphic.getResolution(screen)

local exit
thread.listen("close", function(_, uuid)
    if screen == uuid then
        exit = true
    end
end)

local function getTpsColor(tps)
    if tps < 10 then
        return colors.red
    elseif tps < 15 then
        return colors.orange
    elseif tps < 17 then
        return colors.yellow
    elseif tps < 19 then
        return colors.green
    else
        return colors.lime
    end
end

graphic.clear(screen, colors.black)
while true do
    local tps = host.tps()
    local color = getTpsColor(tps)

    graphic.fill(screen, 1, 1, rx, 1, colors.black, 0, " ")
    graphic.set(screen, 2, 1, colors.black, colors.white, "TPS:")
    graphic.set(screen, 7, 1, colors.black, color, tostring(math.roundTo(tps, 3)))

    graphic.fill(screen, rx, 2, 1, ry, colors.black, 0, " ")
    graphic.fill(screen, rx, math.map(tps, 0, 20, 9, 2), 1, ry, color, 0, " ")
    graphic.copy(screen, 1, 2, rx, ry, -1, 0)
    
    graphic.update(screen)
    os.sleep(0.5)

    if exit then
        break
    end
end