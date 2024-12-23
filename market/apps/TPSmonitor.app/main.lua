local host = require("host")
local graphic = require("graphic")
local colors = require("gui_container").colors
local thread = require("thread")
local screen = ...

local rx, ry = graphic.getResolution(screen)

local baseTh = thread.current()
thread.listen("close", function(_, uuid)
	if screen == uuid then
		baseTh:kill()
		return false
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

local tps, color
local toggle = false

graphic.clear(screen, colors.black)
while true do
	graphic.fill(screen, 1, 1, rx, 1, colors.black, 0, " ")
	graphic.set(screen, 2, 1, colors.black, colors.white, "TPS:")
	graphic.set(screen, 7, 1, colors.black, color or colors.white, tps and tostring(math.roundTo(tps, 3)) or "CHECKING")

	if color then
		graphic.copy(screen, 1, 2, rx, ry, -1, 0)
		graphic.fill(screen, rx, 2, 1, ry, colors.black, 0, " ")
		graphic.fill(screen, rx, math.map(tps, 0, 20, 9, 2), 1, ry, color, 0, toggle and " " or "░")
	end
	
	graphic.update(screen)
	tps = host.tps(2)
	color = getTpsColor(tps)
	toggle = not toggle
end