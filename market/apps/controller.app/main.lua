local uix = require("uix")
local gobjs = require("gobjs")
local gui_container = require("gui_container")
local utils = require("utils")
local system = require("system")
local component = require("component")
local gui = require("gui")
local computer = require("computer")
local event = require("event")
local unicode = require("unicode")
local fs = require("filesystem")
local parser = require("parser")
local screensaver = require("screensaver")
local thread = require("thread")
local sides = require("sides")
local uuid = require("uuid")
local graphic = require("graphic")
local liked = require("liked")
local lastinfo = require("lastinfo")

local screen = ...
local colors = uix.colors
local firmwarePath = system.getResourcePath("firmware/rc_bios/code.lua")
local port = 38710
local ui = uix.manager(screen)
local rx, ry = ui:zoneSize()
local modem = component.proxy(utils.findModem(true) or "")
local tunnels = {}
local allModems = {}
local controlAddress
local finalConnect = false
if modem then
	allModems[modem.address] = true
end
for tunnel in component.list("tunnel") do
	tunnels[tunnel] = true
	allModems[tunnel] = true
end

local mc_1_7_10 = true

if modem then
	utils.openPort(modem, port)
end

local function sendAll(...)
	if modem then
		modem.broadcast(port, ...)
	end
	for tunnel in pairs(tunnels) do
		component.invoke(tunnel, "send", ...)
	end
end

local function advRequest()
	sendAll("rc_radv")
end

local function hash(str)
	local values = {}
	for i = 1, 16 do
		values[i] = ((8 * i * #str) + #str) % 256
	end
	for i = 0, #str - 1 do
		local previous = str:byte(((i - 1) % #str) + 1)
		local byte = str:byte(i + 1)
		local next = str:byte(((i + 1) % #str) + 1)
		local index = ((i + previous + next) % 16) + 1
		values[index] = (((values[index] + byte + 13) * 3 * next) + (next * previous) + ((i + 1) * 6)) % 256
	end
	local hashStr = ""
	for i = 1, #values do
		hashStr = hashStr .. string.char(values[i])
	end
	return hashStr
end

-----------------------------

local layout = ui:create("controller", colors.black)

local warnMsg
if not modem then
	warnMsg = layout:createText(2, layout.sizeY - 1, colors.red, "the modem was not found! install a modem to use the app")
elseif not modem.isWireless() then
	warnMsg = layout:createText(2, layout.sizeY - 1, colors.orange, "only a wired modem was found")
end

local connectList = layout:createCustom(layout:customCenter(0, -4, gobjs.checkboxgroup, 50, 10))
layout:createVText(layout.sizeX / 2, connectList.y - 1, colors.white, "list of devices")
connectList.oneSelect = true

local passwordInput = layout:createInput(layout:centerOneSize(0, 2, 32, nil, nil, "*", nil, nil, nil, "password: "))
local connectButton = layout:createButton(layout:center(-6, 5, 16, 3, colors.white, colors.gray, "connect"))
local refreshButton = layout:createButton(layout:center(8, 5, 9, 3, colors.orange, colors.white, "refresh"))
local wakeAllButton = layout:createButton(2, layout.sizeY - 1, 13, 1, colors.orange, colors.white, "wake-up all")
--local firmwareUpdate = layout:createButton(layout:center(19, 5, 8, 3, colors.orange, colors.white, "update"))

connectButton.y = passwordInput.y + 2
refreshButton.y = passwordInput.y + 2

local tmpThreads = {}

if warnMsg then
	wakeAllButton.y = wakeAllButton.y - 1
end
for tunnel in pairs(tunnels) do
	if warnMsg then
		warnMsg.y = warnMsg.y - 1
	end
	wakeAllButton.y = wakeAllButton.y - 1
	layout:createText(2, layout.sizeY - 1, colors.cyan, "a tunnel card has been found, it can be used to connect to the robot")
	break
end

local function extendArgs(args, id)
	local cmd = args[1]
	if cmd == "rc_out" or cmd == "rc_connect" then
		table.insert(args, id)
	elseif cmd == "rc_exec" or cmd == "rc_fexec" then
		table.insert(args, 3, id)
	end
end

local function deviceSend(address, ...)
	if not address then return end
	local startWaitTime = computer.uptime()
	local args = {...}
	extendArgs(args, uuid.next())
	if tunnels[address] then
		component.invoke(address, "send", table.unpack(args))
	elseif modem then
		modem.send(address, port, table.unpack(args))
	end
end

local requestProcess = false
local function rawDeviceRequest(timeout, address, ...)
	if not address then return end
	requestProcess = true
	local backScreensaver = screensaver.noScreensaver(screen)
	local startWaitTime = computer.uptime()
	local id = uuid.next()
	local args = {...}
	extendArgs(args, id)
	local idRet = "rc_ret:" .. id
	if tunnels[address] then
		component.invoke(address, "send", table.unpack(args))
		while computer.uptime() - startWaitTime < timeout do
			local eventData = {event.pull(0.5, "modem_message", address, nil, 0, nil, idRet)}
			if eventData[1] then
				backScreensaver()
				requestProcess = false
				return {eventData[5]}, table.unpack(eventData, 7)
			end
		end
	elseif modem then
		modem.send(address, port, table.unpack(args))
		while computer.uptime() - startWaitTime < timeout do
			local eventData = {event.pull(0.5, "modem_message", modem.address, address, port, nil, idRet)}
			if eventData[1] then
				backScreensaver()
				requestProcess = false
				return {eventData[5]}, table.unpack(eventData, 7)
			end
		end
	end
	backScreensaver()
	requestProcess = false
end

local function deviceLongRequest(timeout, address, ...)
	if not address then return end
	local data = {rawDeviceRequest(timeout, address, ...)}
	if data[1] then
		return table.unpack(data, 2)
	else
		ui:mwindow(screen, gui.simpleWarn, screen, nil, nil, "no response was received")
		os.sleep(2)
	end
end

local function deviceRequest(...)
	return deviceLongRequest(5, ...)
end

local function statusLongRequest(timeout, ...)
	local address = ...
	if not address then return end
	local clear = gui.saveZone(screen)
	gui.status(screen, nil, nil, "sending a request...")
	local data = {deviceLongRequest(timeout, ...)}
	clear()
	return table.unpack(data)
end

local function statusRequest(...)
	return statusLongRequest(5, ...)
end

function wakeAllButton:onClick()
	sendAll("rc_wake")
	layout:timer(1, advRequest, 1)
end

local noObjErr = "first, select the device you want to control from the list"

local function connectionAttempt()
	gui.status(screen, nil, nil, "connection attempt...")
end

local function manConnect(obj, pass)
	if obj then
		ui:fullStop()
		connectionAttempt()
		local ret = deviceRequest(obj[3], "rc_connect", pass or passwordInput.read.getBuffer())
		if ret == true then
			passwordInput.read.setBuffer("")
			controlAddress = obj[3]
			ui:fullStart()
			rcLayout:select(obj[5])
		else
			ui:forceDraw()
			gui.warn(screen, nil, nil, "incorrect password")
			ui:fullStart()
			ui:draw()
		end
	else
		ui:mwindow(screen, gui.warn, screen, nil, nil, noObjErr)
	end
end

local function findObj(list)
	for i = 1, #list do
		if list[i][2] then
			return i, list[i]
		end
	end
end

local lastConnect
local lastPassword
local function connect()
	local _, obj = findObj(connectList.list)
	if obj then
		lastConnect = table.clone(obj)
		lastPassword = passwordInput.read.getBuffer()
	end
	manConnect(obj)
end

--[[
function firmwareUpdate:onDrop()
	ui:fullStop()
	local obj = findObj()
	if obj then
		local ret = deviceRequest(obj[3], "rc_connect", pass or passwordInput.read.getBuffer())
		if ret == true then
			deviceSend(obj[3], "rc_fexec", [[local code = ...
local eeprom = component.proxy(component.list("eeprom")() or "")
if eeprom and code ~= eeprom.get() then
	setColor(0xef9700)
	setText("firmware\nupdating")
	for i = 1, 3 do
		computer.beep(2000, 0.05)
	end
	eeprom.set(code)
	setColor(currentColor)
	setText("")
end
computer.shutdown(true)] ], assert(fs.readFile(firmwarePath)))
			advRequest()
			connectList.list = {}
		else
			gui.warn(screen, nil, nil, "incorrect password")
		end
	else
		gui.warn(screen, nil, nil, noObjErr)
	end
	ui:fullStart()
	ui:draw()
end
]]

connectButton.onDrop = connect
passwordInput.onTextAcceptedCheck = connect

function refreshButton:onClick()
	advRequest()
	connectList.list = {}
	connectList:draw()
end

function layout:onSelect(reconnect)
	finalConnect = false
	connectList.list = {}
	ui:forceDraw()

	for k, v in pairs(tmpThreads) do
		v:kill()
	end
	tmpThreads = {}

	if controlAddress then
		deviceSend(controlAddress, "rc_out")
		controlAddress = nil
	end

	if reconnect and lastConnect then
		manConnect(lastConnect, lastPassword)
		return
	end

	advRequest()
end

function layout:onFullStart()
	local uptime = computer.uptime()
	for i = 1, #connectList.list do
		if connectList.list[i][4] then
			connectList.list[i][4] = uptime
		end
	end
end

layout:listen("modem_message", function (_, localAddress, sender, senderPort, dist, v1, v2, v3)
	local isTunnel = tunnels[localAddress]
	if allModems[localAddress] and (senderPort == port or isTunnel) and v1 == "rc_adv" then
		local writeAddr = isTunnel and localAddress or sender
		local addTitle
		if isTunnel then
			addTitle = " | tunnel (" .. localAddress:sub(1, 6) .. ")"
		elseif dist == 0 then
			addTitle = " | wired (" .. localAddress:sub(1, 6) .. ")"
		else
			addTitle = " | distance: " .. math.roundTo(dist, 1)
		end
		local tbl = {v2 .. (v3 and (" " .. v3) or "") .. " " .. sender:sub(1, 6) .. addTitle, false, writeAddr, not isTunnel and computer.uptime(), v2}
		for i = 1, #connectList.list do
			local oldTbl = connectList.list[i]
			if oldTbl[3] == writeAddr then
				tbl[2] = oldTbl[2]
				connectList.list[i] = tbl
				tbl = nil
				break
			end
		end
		if tbl then
			table.insert(connectList.list, tbl)
		end
		connectList:draw()
	end
end)

layout:timer(1, function ()
	local updated = false
	for i = #connectList.list, 1, -1 do
		if connectList.list[i][4] and computer.uptime() - connectList.list[i][4] > 5 then
			table.remove(connectList.list, i)
			updated = true
		end
	end
	if not updated then
		connectList:draw()
	end
end, math.huge)

-----------------------------

local infoLayout = ui:create("controller [INFO]", colors.black)
infoLayout:createText(2, 2, colors.white, gui_container.chars.dot .. " to use, flash the EEPROM of the robot/drone with the \"RC Bios\" firmware through the settings>eeprom", rx - 2)
infoLayout:createText(2, 4, colors.white, gui_container.chars.dot .. " if the robot has a screen and a video card, a random 4-character password will be set on it and it will be displayed on the screen", rx - 2)
infoLayout:createText(2, 6, colors.white, gui_container.chars.dot .. " if the robot does not have a screen and/or a video card, then by default it will not have a password", rx - 2)
infoLayout:createText(2, 8, colors.white, gui_container.chars.dot .. " there is always a screen on the drone and therefore a password will be set for the drone in any case", rx - 2)
infoLayout:createText(2, 10, colors.white, gui_container.chars.dot .. " the password will be generated randomly every time you start unless you set your password", rx - 2)
infoLayout:createText(2, 12, colors.white, gui_container.chars.dot .. " in fact, the \"RC Bios\" can be installed on any device, be it a computer or a microcontroller", rx - 2)
infoLayout:createText(2, 14, colors.white, gui_container.chars.dot .. " if a password is not set on the device and a random temporary one cannot be generated (due to the lack of a screen or GPU), then you cannot connect to the device from a distance of more than 8 blocks", rx - 2)
layout:setReturnLayout(infoLayout, colors.green, " INFO ")
infoLayout:setReturnLayout(layout)

-----------------------------

rcLayout = ui:create("controller [Remote Control]", colors.black)
rcLayout:setReturnLayout(layout)

local switchTitle = rcLayout:createText(2, rcLayout.sizeY - 1, colors.white, "allow remote wake-up")
local deviceTypeTitle = rcLayout:createText(2, 2, colors.white)
local colTitle = rcLayout:createText(18, 3, colors.white)
local distanceTitle = rcLayout:createText(2, 3, colors.white)
local wakeUpSwitch = rcLayout:createSwitch(switchTitle.x + unicode.len(switchTitle.text) + 1, rcLayout.sizeY - 1)
local randPass = rcLayout:createButton(2, rcLayout.sizeY - 7, 21, 1, colors.purple, colors.white, "use random password")
local customPass = rcLayout:createButton(2, rcLayout.sizeY - 5, 21, 1, colors.purple, colors.white, "use custom password")
local shutdownButton = rcLayout:createButton(2, rcLayout.sizeY - 3, 10, 1, nil, nil, "shutdown")
local toOther = rcLayout:createButton(shutdownButton.x + shutdownButton.sx + 1, rcLayout.sizeY - 3, 7, 1, colors.white, colors.black, "other")
local blockPeerMove = rcLayout:createSeek(2, rcLayout.sizeY - 9, 16)
local blockPeerMoveText = rcLayout:createText(blockPeerMove.x + blockPeerMove.size + 1, rcLayout.sizeY - 9, colors.white)
local acceleration = rcLayout:createSeek(43, rcLayout.sizeY - 9, 17)
local accelerationText = rcLayout:createText(acceleration.x + acceleration.size + 1, rcLayout.sizeY - 9, colors.white)

local hideButton = rcLayout:createButton(toOther.x + toOther.sx + 1, rcLayout.sizeY - 3, 6, 1, colors.white, colors.black, "hide")
function hideButton:onClick()
	fcontrol:select()
end
ui:bind(28, hideButton)

local currentBlockCount
local currentAcceleration
local maxAcceleration

local startStatPoses = wakeUpSwitch.x + 7
local statuses = {}
for i = 0, 5 do
	table.insert(statuses, rcLayout:createLabel(startStatPoses, (rcLayout.sizeY - 7) + i, 17, 1))
end

local execPoses = statuses[1].x + statuses[1].sx + 3
local luaPoses = execPoses + 6
local checkboxes = {}
for i = 1, 6 do
	local py = (rcLayout.sizeY - 7) + (i - 1)
	local execButton = rcLayout:createButton(execPoses, py, 6, 1, i % 2 == 1 and colors.green or colors.lime, colors.white, "exec")
	rcLayout.style = uix.styles[2]
	local inputStr = rcLayout:createInput(luaPoses, py, rcLayout.sizeX - luaPoses,
		i % 2 == 1 and colors.gray or colors.lightGray,
		colors.white, nil, nil, "lua", nil, nil, nil, nil, "cntr" .. i)
	rcLayout.style = uix.styles[1]
	local checkbox = rcLayout:createCheckbox(execPoses - 2, py)
	checkbox.enableColor = colors.lime
	checkbox.disableColor = colors.lightGray
	checkbox.pointerColor = colors.gray
	table.insert(checkboxes, checkbox)

	local function uploadAutoCode()
		deviceSend(controlAddress, "rc_fexec", "local i, code = ...; tsks[i] = load(code)", i, inputStr.read.getBuffer())
	end

	function inputStr:onTextChanged()
		if checkbox.state then
			uploadAutoCode()
		end
	end

	function checkbox:onSwitch()
		if self.state then
			uploadAutoCode()
		else
			deviceSend(controlAddress, "rc_fexec", "tsks[...] = nil", i)
		end
	end

	function execButton:onDrop()
		local ok, err = ui:mwindow(screen, statusRequest, controlAddress, "rc_exec", inputStr.read.getBuffer())
		if not ok then
			ui:mwindow(screen, gui.warn, screen, nil, nil, tostring(err))
		end
	end
end

for i, v in ipairs(statuses) do
	v.style = "square"
	v.alignment = "left"
	v.back = i % 2 == 1 and colors.lightGray or colors.white
	v.fore = colors.black
end

rcLayout:createText(2, rcLayout.sizeY, colors.white, "power: ")
local progressBar = rcLayout:createProgress(10, rcLayout.sizeY, rcLayout.sizeX - 10, colors.orange, colors.white)

local function statsUpdate(noDraw)
	if not controlAddress then return end
	local getterCode = [[return computer.energy() / computer.maxEnergy(), (function()
	local tbl = {}
	local function detect(name, i)
		local ok, _, result = pcall((drone or robot).detect, i)
		if ok then
			table.insert(tbl, name .. ": " .. tostring(result or "none"))
		else
			table.insert(tbl, name .. ": unknown")
		end
	end
	local offset
	if drone then
		offset = drone.getOffset()
		detect("bottom  ", 0)
		detect("top     ", 1)
		detect("north -Z", 2)
		detect("south +Z", 3)
		detect("west  -X", 4)
		detect("east  +X", 5)
	elseif robot then
		detect("bottom  ", 0)
		detect("top     ", 1)
		--detect("back    ", 2)
		detect("front   ", 3)
		--detect("right   ", 4)
		--detect("left    ", 5)
	end
	return table.concat(tbl, "\n"), offset
end)()]]

	local requestOk, ok, val, strs, offset, acceleration = rawDeviceRequest(5, controlAddress, "rc_exec", getterCode)
	if not requestOk then return true end
	distanceTitle.text = "distance: " .. math.roundTo(requestOk[1], 1)
	if ok then
		if type(val) == "number" then
			progressBar.value = val
			if not noDraw then progressBar:draw() end
		end

		if type(strs) == "string" then
			local strs = parser.split(string, strs, "\n")
			for i, v in ipairs(statuses) do
				v.text = " " .. (strs[i] or "")
				if not noDraw then v:draw() end
			end
		end
	end

	if offset then
		colTitle.text = "collision: " .. math.roundTo(offset, 1)
		colTitle:draw()
	end
	distanceTitle:draw()
end

local bgThread = thread.createBackground(function ()
	while true do
		if finalConnect and controlAddress and not requestProcess and (not rcLayout.active or screensaver.current(screen)) then
			deviceSend(controlAddress, "rc_fexec", "") --resetting the shutdown timer when the blocking window is displayed
		end
		os.sleep(3)
	end
end)

local bgThread2 = thread.createBackground(function ()
	while true do
		if finalConnect and controlAddress and not requestProcess and statsUpdate() then
			controlAddress = nil
			layout:select()
		end
		os.sleep(1)
	end
end)

bgThread:resume()
bgThread2:resume()

local function blockPeerMoveTextUpdate(noDraw)
	blockPeerMoveText.text = "blocks for movement: " .. currentBlockCount .. " "
	if not noDraw then blockPeerMoveText:draw() end
end

local function accelerationTextUpdate(noDraw)
	accelerationText.text = "acceleration: " .. math.roundTo(currentAcceleration, 1) .. "   "
	if not noDraw then accelerationText:draw() end
end

function toOther:onClick()
	otherLayout:select()
end

function blockPeerMove:onSeek(value)
	currentBlockCount = math.mapRound(value, 0, 1, 1, 16)
	blockPeerMoveTextUpdate()
end

function acceleration:onSeek(value)
	currentAcceleration = math.map(value, 0, 1, 0, maxAcceleration)
	accelerationTextUpdate()
end

function acceleration:onTouch(state)
	if not state then
		ui:mwindow(screen, statusRequest, controlAddress, "rc_exec", "drone.setAcceleration(...)", currentAcceleration)
	end
end

function shutdownButton:onDrop()
	ui:fullStop()
	local clear = gui.saveZone(screen)
	if gui.yesno(screen, nil, nil, "are you sure you want to turn off the device?") then
		clear()
		deviceSend(controlAddress, "rc_fexec", "computer.shutdown()")
		controlAddress = nil
		layout:select()
		return
	end
	ui:fullStart()
	ui:draw()
end

function randPass:onDrop()
	ui:fullStop()
	local clear = gui.saveZone(screen)
	if gui.yesno(screen, nil, nil, "are you sure you want to reset your password and use a random password?") then
		clear()
		statusRequest(controlAddress, "rc_exec", "passwordHash = nil; component.invoke(component.list('eeprom')(), 'setData', '')")
	end
	ui:fullStart()
	ui:draw()
end

function customPass:onDrop()
	ui:fullStop()
	local clear = gui.saveZone(screen)
	local password = gui.comfurmPassword(screen)
	if password then
		clear()
		statusRequest(controlAddress, "rc_exec", "passwordHash = ...; component.invoke(component.list('eeprom')(), 'setData', passwordHash)", hash(password))
	end
	ui:fullStart()
	ui:draw()
end

local actionsPosX, actionsPosY = 39, 2
local actionsTitle = rcLayout:createText(1, 1, colors.white, "actions")
local actionsList = rcLayout:createCustom(1, 1, gobjs.checkboxgroup, 13, 5)
actionsList.oneSelect = true
actionsList.list = {
	{"swing"},
	{"use"},
	{"use snk"},
	{"place"},
	{"place snk"},
	{"drain"},
	{"drain max"},
	{"fill"},
	{"fill max"},
	{"drop"},
	{"drop max"},
	{"suck"},
	{"suck max"}
}

local actionsFuncs = {
	"return (robot or drone).swing(...)",
	"return (robot or drone).use(...)",
	"return (robot or drone).use(..., true)",
	"return (robot or drone).place(...)",
	"return (robot or drone).place(..., true)",
	"return (robot or drone).drain(..., 1)",
	"return (robot or drone).drain(..., math.huge)",
	"return (robot or drone).fill(..., 1)",
	"return (robot or drone).fill(..., math.huge)",
	"return (robot or drone).drop(..., 1)",
	"return (robot or drone).drop(..., math.huge)",
	"return (robot or drone).suck(..., 1)",
	"return (robot or drone).suck(..., math.huge)"
}

local customBinds = {}
local function customBind(code, item)
	if not customBinds[item] then
		customBinds[item] = {}
	end
	customBinds[item][code] = true
	ui:bind(code, item)
end

local controls = {}
local move = {
	rcLayout:createButton(6, 5, 4, 2, colors.purple, colors.white),
	rcLayout:createButton(10, 7, 4, 2, colors.purple, colors.white),
	rcLayout:createButton(6, 9, 4, 2, colors.purple, colors.white),
	rcLayout:createButton(2, 7, 4, 2, colors.purple, colors.white),
	rcLayout:createButton(6+9, 5, 4, 2, colors.orange, colors.white),
	rcLayout:createButton(6+9, 9, 4, 2, colors.orange, colors.white)
}

-- WASD, space, shift
customBind(17, move[1])
customBind(32, move[2])
customBind(31, move[3])
customBind(30, move[4])
customBind(57, move[5])
customBind(42, move[6])

-- arrows
customBind(200, move[1])
customBind(205, move[2])
customBind(208, move[3])
customBind(203, move[4])

local actionOffset = 18
local firstActionPosX, firstActionPosY = actionOffset + 6, 5
local upActPosX, upActPosY = actionOffset + 6+9, 5
local downActPosX, downActPosY = actionOffset + 6+9, 9
local action = {
	rcLayout:createButton(firstActionPosX, firstActionPosY, 4, 2, colors.red, colors.white),
	rcLayout:createButton(actionOffset + 10, 7, 4, 2, colors.red, colors.white),
	rcLayout:createButton(actionOffset + 6, 9, 4, 2, colors.red, colors.white),
	rcLayout:createButton(actionOffset + 2, 7, 4, 2, colors.red, colors.white),
	rcLayout:createButton(upActPosX, upActPosY, 4, 2, colors.pink, colors.white),
	rcLayout:createButton(downActPosX, downActPosY, 4, 2, colors.pink, colors.white)
}

local function createDroneControl()
	local droneMoveCode = [[local dx, dy, dz = ...
ox = (ox or 0) + dx
oy = (oy or 0) + dy
oz = (oz or 0) + dz
drone.move(dx, dy, dz)]]

	local droneVirtualRotation = 2
	local rawMvTitle = {"+Z", "-X", "-Z", "+X"}
	local mvTitle = {}

	local mdx, mdy, mdz = 0, 0, 0
	local function droneMove(dx, dy, dz)
		if droneVirtualRotation == 1 then
			local t = dx
			dx = -dz
			dz = t
		elseif droneVirtualRotation == 2 then
			dx = -dx
			dz = -dz
		elseif droneVirtualRotation == 3 then
			local t = dx
			dx = dz
			dz = -t
		end

		mdx, mdy, mdz = mdx + dx, mdy + dy, mdz + dz
		if math.abs(mdx) >= 0.25 then
			dx = math.round(mdx * 4) / 4
			mdx = 0
		else
			dx = 0
		end
		if math.abs(mdy) >= 0.25 then
			dy = math.round(mdy * 4) / 4
			mdy = 0
		else
			dy = 0
		end
		if math.abs(mdz) >= 0.25 then
			dz = math.round(mdz * 4) / 4
			mdz = 0
		else
			dz = 0
		end
		if dx ~= 0 or dy ~= 0 or dz ~= 0 then
			deviceSend(controlAddress, "rc_fexec", droneMoveCode, dx, dy, dz)
		end
	end

	controls.touchControl = rcLayout:createCanvas(rcLayout.sizeX - 25, 2, 24, 12, colors.white, 0, " ")

	local oPosX, oPosY
	function controls.touchControl:userEvent(eventData)
		if eventData[1] == "drag" then
			oPosX = oPosX or eventData[3]
			oPosY = oPosY or eventData[4]
			
			local dx, dy = ((eventData[3] - oPosX) / (self.sx - 1)) * currentBlockCount, ((eventData[4] - oPosY) / (self.sy - 1)) * currentBlockCount
			droneMove(-dx, 0, -dy)
			oPosX, oPosY = eventData[3], eventData[4]
		elseif eventData[1] == "drop" then
			oPosX, oPosY = nil, nil
		elseif eventData[1] == "touch" then
			oPosX, oPosY = eventData[3], eventData[4]
		elseif eventData[1] == "scroll" then
			droneMove(0, (eventData[5] / 10) * currentBlockCount, 0)
		end
	end



	controls.touchControl2 = rcLayout:createCanvas(rcLayout.sizeX - 28, 2, 2, 12, colors.white, 0, " ")
	controls.touchControl2:draw()
	controls.touchControl2:set(1, 1, colors.white, colors.black, "+Y")
	controls.touchControl2:set(1, 12, colors.white, colors.black, "-Y")

	function controls.touchControl2:userEvent(eventData)
		if eventData[1] == "drag" then
			local dy = ((eventData[4] - oPosY) / self.sy) * currentBlockCount
			droneMove(0, -dy, 0)
			oPosX, oPosY = eventData[3], eventData[4]
		elseif eventData[1] == "drop" then
			oPosX, oPosY = nil, nil
		elseif eventData[1] == "touch" then
			oPosX, oPosY = eventData[3], eventData[4]
		elseif eventData[1] == "scroll" then
			droneMove(0, (eventData[5] / 10) * currentBlockCount, 0)
		end
	end



	controls.home = rcLayout:createButton(rcLayout.sizeX - 41, 13, 12, 1, colors.purple, colors.white, "HOME")

	function controls.home:onDrop()
		ui:mwindow(screen, function ()
			if gui.yesno(screen, nil, nil, "are you sure you want to return to your home point?") then
				deviceSend(controlAddress, "rc_fexec", "drone.move(-(ox or 0), -(oy or 0), -(oz or 0)); ox, oy, oz = nil, nil, nil")
				mdx, mdy, mdz = 0, 0, 0
			end
		end)
	end



	controls.setHome = rcLayout:createButton(rcLayout.sizeX - 41, 11, 12, 1, colors.purple, colors.white, "SET HOME")

	function controls.setHome:onDrop()
		ui:mwindow(screen, function ()
			if gui.yesno(screen, nil, nil, "are you sure you want to set this point as the home point for the drone?") then
				deviceSend(controlAddress, "rc_fexec", "ox, oy, oz = nil, nil, nil")
				mdx, mdy, mdz = 0, 0, 0
			end
		end)
	end



	controls.center = rcLayout:createButton(rcLayout.sizeX - 41, 9, 12, 1, colors.purple, colors.white, "CENTER")

	function controls.center:onDrop()
		deviceSend(controlAddress, "rc_fexec", [[local nx, ny, nz = math.floor((ox or 0) + 0.5), math.floor((oy or 0) + 0.5), math.floor((oz or 0) + 0.5)
local mx, my, mz = nx - (ox or 0), ny - (oy or 0), nz - (oz or 0)
drone.move(mx, my, mz)
ox, oy, oz = nx, ny, nz]])
	end

	action[1].x = firstActionPosX
	action[1].y = firstActionPosY
	move[1].onDrop = function (self)
		droneMove(0, 0, currentBlockCount)
	end
	move[2].onDrop = function (self)
		droneMove(-currentBlockCount, 0, 0)
	end
	move[3].onDrop = function (self)
		droneMove(0, 0, -currentBlockCount)
	end
	move[4].onDrop = function (self)
		droneMove(currentBlockCount, 0, 0)
	end

	move[5].text = "+Y"
	action[5].text = "+Y"
	action[5].x = upActPosX
	action[5].y = upActPosY
	move[5].onDrop = function (self)
		droneMove(0, currentBlockCount, 0)
	end
	move[6].text = "-Y"
	action[6].text = "-Y"
	action[6].x = downActPosX
	action[6].y = downActPosY
	move[6].onDrop = function (self)
		droneMove(0, -currentBlockCount, 0)
	end

	local function getArrowColor(str, def)
		if str == "+Z" then
			return colors.red
		elseif str == "-Z" then
			return colors.lightBlue
		end
		return def or colors.black
	end

	local function updateRotation(updateArrows)
		for i = 0, 3 do
			mvTitle[i + 1] = rawMvTitle[((i + droneVirtualRotation) % 4) + 1]

			local arrow = move[i + 1]
			arrow.text = mvTitle[i + 1]
			arrow.fore = getArrowColor(arrow.text, colors.white)
			if updateArrows then
				arrow:draw()
			end

			arrow = action[i + 1]
			arrow.text = mvTitle[i + 1]
			if updateArrows then
				arrow:draw()
			end
		end

		controls.touchControl:draw()
		controls.touchControl:set(12, 1, colors.white, getArrowColor(mvTitle[1]), mvTitle[1])
		controls.touchControl:set(24, 6, colors.white, getArrowColor(mvTitle[2]), mvTitle[2], true)
		controls.touchControl:set(12, 12, colors.white, getArrowColor(mvTitle[3]), mvTitle[3])
		controls.touchControl:set(1, 6, colors.white, getArrowColor(mvTitle[4]), mvTitle[4], true)
		controls.touchControl:set(7, 6, colors.white, colors.black, "drag control")
	end

	updateRotation()

	controls.l1 = rcLayout:createButton(2, 12, 4, 2, colors.green, colors.white, "<<")
	customBind(16, controls.l1)
	function controls.l1:onDrop()
		droneVirtualRotation = droneVirtualRotation - 1
		if droneVirtualRotation < 0 then
			droneVirtualRotation = 3
		end
		updateRotation(true)
	end

	controls.l2 = rcLayout:createButton(10, 12, 4, 2, colors.green, colors.white, ">>")
	customBind(18, controls.l2)
	function controls.l2:onDrop()
		droneVirtualRotation = droneVirtualRotation + 1
		if droneVirtualRotation > 3 then
			droneVirtualRotation = 0
		end
		updateRotation(true)
	end



	controls[1] = rcLayout:createText(15, 12, colors.white, "sync direction:")
	controls.syncDir = rcLayout:createSwitch(controls[1].x + #controls[1].text + 1, controls[1].y)

	function controls.syncDir:onSwitch()
		if self.state and not component.tablet then
			ui:mwindow(screen, gui.warn, screen, nil, nil, "this option is only available on the tablet")
			self.state = false
			self:draw()
		elseif self.state then
			if not tmpThreads.autoSync then
				tmpThreads.autoSync = thread.create(function ()
					local oldDir = droneVirtualRotation
					while true do
						local rawYaw = component.tablet.getYaw()
						local dir
						if mc_1_7_10 then
							dir = math.floor((math.abs(rawYaw) / (360 / 4)) + 0.5)
							if dir == 4 then dir = 0 end
						else
							local yaw = math.floor(((-math.abs(rawYaw) + 180) / (360 / 4)) + 0.5)
							if yaw == 2 or yaw == -2 then
								if rawYaw > 0 then
									dir = 2
								else
									dir = 0
								end
							elseif yaw == 1 then
								if rawYaw > 0 then
									dir = 1
								else
									dir = 3
								end
							elseif yaw == -1 then
								if rawYaw > 0 then
									dir = 3
								else
									dir = 1
								end
							else
								if rawYaw > 0 then
									dir = 0
								else
									dir = 2
								end
							end
						end
						if dir ~= oldDir then
							droneVirtualRotation = dir
							updateRotation(true)
							oldDir = dir
						end
						os.sleep(0.5)
					end
				end)
				tmpThreads.autoSync:resume()
			end
		elseif tmpThreads.autoSync then
			tmpThreads.autoSync:kill()
			tmpThreads.autoSync = nil
		end
	end

	if component.tablet then
		controls.syncDir.state = true
		controls.syncDir:onSwitch()
	end

	actionsTitle.x = actionsPosX
	actionsTitle.y = actionsPosY
	actionsList.x = actionsTitle.x - 1
	actionsList.y = actionsTitle.y + 1
	uix.updateDrawZone(actionsList)
end

local function createRobotControl()
	local robotMoveCode = [[local side, count = ...
local ci = 0 for i = 1, count do
	if not robot.move(side) then
		break
	else
		ci = ci + 1
	end
	ut()
end
return ci]]

	controls[1] = rcLayout:createText(2, 12, colors.white, "feedback:")
	controls.feedback = rcLayout:createSwitch(controls[1].x + #controls[1].text + 1, controls[1].y, true)

	local function actionOnSide(side)
		local i = findObj(actionsList.list)
		local execString
		if i then
			execString = actionsFuncs[i]
		else
			return
		end

		if controls.feedback.state then
			if not select(2, assert(ui:mwindow(screen, statusLongRequest, 15, controlAddress, "rc_exec", execString, side))) then
				ui:mwindow(screen, gui.warn, screen, nil, nil, "failed to perform action")
			end
		else
			deviceSend(controlAddress, "rc_fexec", execString, side)
		end
	end

	local function robotMove(side)
		if controls.feedback.state then
			local blocks = math.floor(select(2, assert(ui:mwindow(screen, statusLongRequest, 15, controlAddress, "rc_exec", robotMoveCode, side, currentBlockCount))))
			if blocks ~= currentBlockCount then
				ui:mwindow(screen, gui.warn, screen, nil, nil, "the movement failed, " .. blocks .." blocks were passed")
			end
		else
			deviceSend(controlAddress, "rc_fexec", robotMoveCode, side, currentBlockCount)
		end
	end

	for i = 1, 4 do
		local arrow = move[i]
		arrow.fore = colors.white
	end

	local aOffset = -3

	action[1].x = firstActionPosX + 4 + aOffset
	action[1].y = firstActionPosY + 2
	action[1].text = "forw"
	action[1].onDrop = function()
		actionOnSide(sides.front)
	end
	action[5].text = "up"
	action[5].x = upActPosX + aOffset
	action[5].y = upActPosY
	action[5].onDrop = function()
		actionOnSide(sides.up)
	end
	action[6].text = "down"
	action[6].x = downActPosX + aOffset
	action[6].y = downActPosY
	action[6].onDrop = function()
		actionOnSide(sides.down)
	end

	move[1].text = "forw"
	move[1].onDrop = function (self)
		robotMove(sides.forward)
	end
	move[2].text = "righ"
	move[2].onDrop = function (self)
		deviceSend(controlAddress, "rc_fexec", "robot.turn(true)")
	end
	move[3].text = "back"
	move[3].onDrop = function (self)
		robotMove(sides.back)
	end
	move[4].text = "left"
	move[4].onDrop = function (self)
		deviceSend(controlAddress, "rc_fexec", "robot.turn(false)")
	end

	move[5].text = "up"
	move[5].onDrop = function (self)
		robotMove(sides.up)
	end
	move[6].text = "down"
	move[6].onDrop = function (self)
		robotMove(sides.down)
	end

	actionsTitle.x = actionsPosX - 2
	actionsTitle.y = actionsPosY + 3
	actionsList.x = actionsTitle.x - 1
	actionsList.y = actionsTitle.y + 1
	uix.updateDrawZone(actionsList)
end

function rcLayout:onSelect(devicetype)
	if not devicetype then return end

	for _, object in pairs(controls) do
		object:destroy()
	end
	controls = {}

	local initCode = [[local code = ...
local function lend()
	for i = 1, 6 do
		tsks[i] = nil
	end
end
if #code < 2048 or not load(code) then
	return false, "received firmware is damaged"
end
local eeprom = component.proxy(component.list("eeprom")() or "")
if eeprom and code ~= eeprom.get() then
	setColor(0xef9700)
	setText("firmware\nupdating")
	for i = 1, 3 do
		computer.beep(2000, 0.05)
	end
	eeprom.set(code)
	setColor(currentColor)
	setText("")
	lend()
	return true, true
end
lend()
return true]]
	if select(2, assert(select(2, assert(deviceRequest(controlAddress, "rc_exec", initCode, assert(fs.readFile(firmwarePath))))))) then
		deviceSend(controlAddress, "rc_fexec", "computer.shutdown(true)")
		layout:select(controlAddress)
		return
	end
	wakeUpSwitch.state = not not select(2, assert(deviceRequest(controlAddress, "rc_exec", "return (tunnel and tunnel.getWakeMessage() == \"rc_wake\") or (modem and modem.getWakeMessage() == \"rc_wake\")")))
	
	colorpic.disabledHidden = true
	--[[
	if devicetype == "drone" then
		colorpic.disabledHidden = false
		colorpic:setColor(select(2, assert(deviceRequest(controlAddress, "rc_exec", "return drone.getLightColor()"))))
	elseif devicetype == "robot" then
		colorpic.disabledHidden = false
		colorpic:setColor(select(2, assert(deviceRequest(controlAddress, "rc_exec", "return robot.getLightColor()"))))
	end
	]]
	if devicetype == "drone" or devicetype == "robot" then
		for _, v in pairs(move) do
			v.disabledHidden = false
		end
		for i, v in pairs(action) do
			v.disabledHidden = not (devicetype == "drone" or i == 1 or i == 5 or i == 6)
		end
		colorpic.disabledHidden = false
		colorpic:setColor(0xffffff)
	else
		for _, v in pairs(move) do
			v.disabledHidden = true
		end
		for _, v in pairs(action) do
			v.disabledHidden = true
		end
	end

	blockPeerMove.value = 0
	deviceTypeTitle.text = "device type: " .. devicetype

	colTitle.disabledHidden = true
	blockPeerMove.disabledHidden = true
	blockPeerMoveText.disabledHidden = true
	acceleration.disabledHidden = true
	accelerationText.disabledHidden = true
	if devicetype == "robot" then
		blockPeerMove.disabledHidden = false
		blockPeerMoveText.disabledHidden = false
		for i, v in ipairs(statuses) do
			v.disabledHidden = i > 3
		end

		currentBlockCount = 1
		blockPeerMoveTextUpdate(true)
		statsUpdate(true)
		createRobotControl()
	elseif devicetype == "drone" then
		blockPeerMove.disabledHidden = false
		blockPeerMoveText.disabledHidden = false
		acceleration.disabledHidden = false
		accelerationText.disabledHidden = false
		colTitle.disabledHidden = false
		for i, v in ipairs(statuses) do
			v.disabledHidden = false
		end

		currentBlockCount = 1
		currentAcceleration = 1
		maxAcceleration = select(2, assert(deviceRequest(controlAddress, "rc_exec", "return drone.setAcceleration(math.huge)")))
		currentAcceleration = maxAcceleration
		acceleration.value = 1
		blockPeerMoveTextUpdate(true)
		accelerationTextUpdate(true)
		statsUpdate(true)
		createDroneControl()
	else
		for i, v in ipairs(statuses) do
			v.disabledHidden = true
		end
	end

	for i, v in ipairs(checkboxes) do
		v.state = false
	end

	finalConnect = true
end

function wakeUpSwitch:onSwitch()
	if self.state then
		statusRequest(controlAddress, "rc_exec", "if tunnel then tunnel.setWakeMessage('rc_wake') end if modem then modem.setWakeMessage('rc_wake') end")
	else
		statusRequest(controlAddress, "rc_exec", "if tunnel then tunnel.setWakeMessage() end if modem then modem.setWakeMessage() end")
	end
end

-----------------------------

local function keyboardCheck(eventData)
	return table.exists(lastinfo.keyboards[screen], eventData[2])
end

thread.create(function ()
	while true do
		local eventData = {event.pull()}
		local isDown = eventData[1] == "key_down"
		if rcLayout ~= ui.current and (isDown or eventData[1] == "key_up") and keyboardCheck(eventData) then
			for item, codes in pairs(customBinds) do
				if codes[eventData[4]] then
					if isDown then
						if item.onClick then
							item:onClick()
						end
					elseif item.onDrop then
						item:onDrop()
					end
				end
			end
		end
	end
end):resume()

local retResX, retResY = graphic.getResolution(screen)
fcontrol = ui:createCustom(graphic.createWindow(screen, 1, 1, 1, 1), colors.black, "square")

function fcontrol:onSelect()
	graphic.setResolution(screen, 1, 1)
end

function fcontrol:onUnselect()
	graphic.setResolution(screen, retResX, retResY)
end

local fcontrolBack = fcontrol:createButton(1, 1, 1, 1, colors.orange, colors.white, "<")
function fcontrolBack:onClick()
	rcLayout:select()
end

ui:bind(28, fcontrolBack)

-----------------------------

otherLayout = ui:create("controller [Remote Control]", colors.black)
otherLayout:setReturnLayout(rcLayout)
colorpic = otherLayout:createColorpic(2, 2, 13, 1, "light color", 0xffffff, true)

function colorpic:onColor(_, color)
	deviceSend(controlAddress, "rc_color", color)
end

ui:loop()

bgThread:kill()
bgThread2:kill()
if controlAddress then
	deviceSend(controlAddress, "rc_out")
end