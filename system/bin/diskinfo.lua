local screen, nickname, diskUuid = ...

local graphic = require("graphic")
local gui_container = require("gui_container")
local colors = gui_container.colors
local event = require("event")
local fs = require("filesystem")
local paths = require("paths")
local gui = require("gui")
local uix = require("uix")
local registry = require("registry")
local component = require("component")

local window = gui.customWindow(screen)
local layout = uix.create(window, nil, uix.styles[2])

window:clear(colors.white)
window:fill(1, 1, window.sizeX, 1, colors.gray, 0, " ")
window:set(window.sizeX - 2, 1, colors.red, colors.white, " X ")
window:set(2, 1, colors.gray, colors.white, "disk-info")

local proxy = component.proxy(diskUuid)
local size, sizeWithBaseCost, filesCount, dirsCount = fs.size(fs.point(diskUuid))
local totalSpace = proxy.spaceTotal() / 1024
local usedSpace = proxy.spaceUsed() / 1024

layout:createText(2, 3, 0x000000, "uuid       : " .. diskUuid)
layout:createText(2, 4, 0x000000, "total space: " .. math.roundTo(totalSpace, 1) .. " KB")
layout:createText(2, 5, 0x000000, "used  space: " .. math.roundTo(usedSpace, 1) .. " KB")
layout:createText(2, 6, 0x000000, "free  space: " .. math.roundTo(totalSpace - usedSpace, 1) .. " KB")
layout:createText(2, 7, 0x000000, "f/d count  : " .. filesCount .. "-files / " .. (dirsCount - 1) .. "-dirs")

layout:draw()

while true do
	local eventData = {event.pull()}
	local windowEventData = window:uploadEvent(eventData)
	layout:uploadEvent(windowEventData)

	if windowEventData[1] == "key_down" then
		if windowEventData[4] == 28 then
			break
		end
	elseif windowEventData[1] == "touch" then
		if windowEventData[3] >= window.sizeX - 2 and windowEventData[4] == 1 then
			break
		end
	end
end