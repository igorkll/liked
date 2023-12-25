local host = require("host")
local braille = require("braille")
local graphic = require("graphic")
local colors = require("gui_container").colors
local thread = require("thread")
local lastinfo = require("lastinfo")
local screen = ...

local tpsHistory = {}
local exit

thread.listen("key_down", function(_, uuid, c1, c2)
    if table.exists(lastinfo.keyboards[screen], uuid) and c1 == 13 and c2 == 28 then
        exit = true
    end
end)

while true do
    local tps = host.tps()
    graphic.clear(screen, colors.black)
    graphic.set(screen, 2, 1, colors.black, colors.red, tostring(math.roundTo(tps, 1)))
    table.insert(tpsHistory, tps)
    if #tpsHistory > 12 then
        table.remove(tpsHistory, 1)
    end
    local drawPos = 1
    local oldPoint
    for i, point in ipairs(tpsHistory) do
        if i % 2 == 0 and oldPoint then
            local tbl = {}
            for i = 4, 1, -1 do
                local nval = i * 5
                table.insert(tbl, {oldPoint > nval, point > nval})
            end
            tbl[1][1] = true
            graphic.set(drawPos, 2, colors.black, colors.orange, braille.make(tbl))
            drawPos = drawPos + 1
        end
        oldPoint = point
    end
    graphic.update(screen)
    os.sleep(0.5)

    if exit then
        break
    end
end