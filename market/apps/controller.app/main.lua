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

connectButton.y = passwordInput.y + 2
refreshButton.y = passwordInput.y + 2

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

local function deviceSend(address, ...)
    if not address then return end
    local startWaitTime = computer.uptime()
    if tunnels[address] then
        component.invoke(address, "send", ...)
    elseif modem then
        modem.send(address, port, ...)
    end
end

local function rawDeviceRequest(address, ...)
    if not address then return end
    local backScreensaver = screensaver.noScreensaver(screen)
    local startWaitTime = computer.uptime()
    if tunnels[address] then
        component.invoke(address, "send", ...)
        while computer.uptime() - startWaitTime < 5 do
            local eventData = {event.pull(0.5, "modem_message", address, nil, 0, nil, "rc_ret")}
            if eventData[1] then
                backScreensaver()
                return true, table.unpack(eventData, 7)
            end
        end
    elseif modem then
        modem.send(address, port, ...)
        while computer.uptime() - startWaitTime < 5 do
            local eventData = {event.pull(0.5, "modem_message", modem.address, address, port, nil, "rc_ret")}
            if eventData[1] then
                backScreensaver()
                return true, table.unpack(eventData, 7)
            end
        end
    end
    backScreensaver()
end

local function deviceRequest(address, ...)
    if not address then return end
    local data = {rawDeviceRequest(address, ...)}
    if data[1] then
        return table.unpack(data, 2)
    else
        ui:func(gui.simpleWarn, screen, nil, nil, "no response was received")
        os.sleep(2)
    end
end

local function statusRequest(...)
    local address = ...
    if not address then return end
    local clear = gui.saveZone(screen)
    gui.status(screen, nil, nil, "sending a request...")
    local data = {deviceRequest(...)}
    clear()
    return table.unpack(data)
end

function wakeAllButton:onClick()
    sendAll("rc_wake")
    layout:timer(1, advRequest, 1)
end

local function manConnect(obj)
    if obj then
        ui:fullStop()
        gui.status(screen, nil, nil, "connection attempt...")
        local ret = deviceRequest(obj[3], "rc_connect", passwordInput.read.getBuffer())
        if ret == true then
            passwordInput.read.setBuffer("")
            controlAddress = obj[3]
            ui:fullStart()
            finalConnect = false
            rcLayout:select(obj[5])
        else
            ui:forceDraw()
            gui.warn(screen, nil, nil, "incorrect password")
            ui:fullStart()
            ui:draw()
        end
    else
        ui:func(gui.warn, screen, nil, nil, "first, select the device you want to control from the list")
    end
end

local lastConnect
local function connect()
    local obj
    for i = 1, #connectList.list do
        if connectList.list[i][2] then
            obj = connectList.list[i]
        end
    end

    if obj then
        lastConnect = table.clone(obj)
    end
    manConnect(obj)
end

connectButton.onDrop = connect
passwordInput.onTextAcceptedCheck = connect

function refreshButton:onClick()
    advRequest()
    connectList.list = {}
    connectList:draw()
end

function layout:onSelect(reconnect)
    if reconnect and lastConnect then
        ui:draw()
        manConnect(lastConnect)
        return
    end

    advRequest()
    connectList.list = {}
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
            addTitle = " | tunnel " .. localAddress:sub(1, 6)
        elseif dist == 0 then
            addTitle = " | wired " .. localAddress:sub(1, 6)
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
infoLayout:createText(2, 4, colors.white, gui_container.chars.dot .. " if the robot has a screen and a video card, a random 8-character password will be set on it and it will be displayed on the screen", rx - 2)
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
local offsetTitle = rcLayout:createText(2, 3, colors.white)
local wakeUpSwitch = rcLayout:createSwitch(switchTitle.x + unicode.len(switchTitle.text) + 1, rcLayout.sizeY - 1)
local randPass = rcLayout:createButton(2, rcLayout.sizeY - 7, 21, 1, colors.purple, colors.white, "use random password")
local customPass = rcLayout:createButton(2, rcLayout.sizeY - 5, 21, 1, colors.purple, colors.white, "use custom password")
local shutdownButton = rcLayout:createButton(2, rcLayout.sizeY - 3, 10, 1, nil, nil, "shutdown")
local colorpic = rcLayout:createColorpic(shutdownButton.x + shutdownButton.sx + 1, rcLayout.sizeY - 3, 13, 1, "light color", 0xffffff, true)
local blockPeerMove = rcLayout:createSeek(2, rcLayout.sizeY - 9, 16)
local blockPeerMoveText = rcLayout:createText(blockPeerMove.x + blockPeerMove.size + 1, rcLayout.sizeY - 9, colors.white)
local acceleration = rcLayout:createSeek(43, rcLayout.sizeY - 9, 17)
local accelerationText = rcLayout:createText(acceleration.x + acceleration.size + 1, rcLayout.sizeY - 9, colors.white)
local currentBlockCount
local currentAcceleration
local maxAcceleration

local startStatPoses = wakeUpSwitch.x + 7
local statuses = {}
for i = 0, 5 do
    table.insert(statuses, rcLayout:createLabel(startStatPoses, (rcLayout.sizeY - 7) + i, 20, 1))
end

local execPoses = statuses[1].x + statuses[1].sx + 1
local luaPoses = execPoses + 6
for i = 1, 6 do
    local py = (rcLayout.sizeY - 7) + (i - 1)
    local execButton = rcLayout:createButton(execPoses, py, 6, 1, i % 2 == 1 and colors.green or colors.lime, colors.white, "exec")
    rcLayout.style = uix.styles[2]
    local inputStr = rcLayout:createInput(luaPoses, py, rcLayout.sizeX - luaPoses,
        i % 2 == 1 and colors.gray or colors.lightGray,
        colors.white, nil, nil, "lua", nil, nil, nil, nil, "cntr" .. i)
    rcLayout.style = uix.styles[1]

    function execButton:onDrop()
        ui:fullStop()
        local ok, err = statusRequest(controlAddress, "rc_exec", inputStr.read.getBuffer())
        if not ok then
            gui.warn(screen, nil, nil, tostring(err))
        end
        ui:fullStart()
        ui:draw()
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

    local requestOk, ok, val, strs, offset, acceleration = rawDeviceRequest(controlAddress, "rc_exec", getterCode)
    if not requestOk then return true end
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
        offsetTitle.text = "offset: " .. math.roundTo(offset, 1)
        if offset > 1 then
            offsetTitle.text = offsetTitle.text .. " - POSSIBLE COLLISIONS WITH BLOCKS"
        else
            offsetTitle.text = offsetTitle.text .. string.rep(" ", 38)
        end
        offsetTitle:draw()
    end
end

rcLayout:thread(function ()
    while true do
        if finalConnect and statsUpdate() then
            controlAddress = nil
            layout:select()
        end
        os.sleep(1)
    end
end)

local function blockPeerMoveTextUpdate(noDraw)
    blockPeerMoveText.text = "blocks for movement: " .. currentBlockCount .. " "
    if not noDraw then blockPeerMoveText:draw() end
end

local function accelerationTextUpdate(noDraw)
    accelerationText.text = "acceleration: " .. math.roundTo(currentAcceleration, 1) .. "   "
    if not noDraw then accelerationText:draw() end
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
        ui:func(function ()
            statusRequest(controlAddress, "rc_exec", "drone.setAcceleration(...)", currentAcceleration)
        end)
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

function colorpic:onColor(_, color)
    statusRequest(controlAddress, "rc_exec", "setColor(" .. color .. ")")
end

function rcLayout:onUnselect()
    if controlAddress then
        statusRequest(controlAddress, "rc_out")
        controlAddress = nil
    end
end

local controls = {}

local function createDroneControl()
    local droneMoveCode = [[local dx, dy, dz = ...
ox = (ox or 0) + dx
oy = (oy or 0) + dy
oz = (oz or 0) + dz
drone.move(dx, dy, dz)]]

    local mdx, mdy, mdz = 0, 0, 0
    local function droneMove(dx, dy, dz)
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
    controls.touchControl:draw()
    controls.touchControl:set(12, 1, colors.white, colors.black, "+Z")
    controls.touchControl:set(12, 12, colors.white, colors.black, "-Z")
    controls.touchControl:set(24, 6, colors.white, colors.black, "-X", true)
    controls.touchControl:set(1, 6, colors.white, colors.black, "+X", true)
    controls.touchControl:set(7, 6, colors.white, colors.black, "drag control")

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
        ui:func(function ()
            if gui.yesno(screen, nil, nil, "are you sure you want to return to your home point?") then
                deviceSend(controlAddress, "rc_fexec", "drone.move(-(ox or 0), -(oy or 0), -(oz or 0)); ox, oy, oz = nil, nil, nil")
                mdx, mdy, mdz = 0, 0, 0
            end
        end)
    end



    controls.setHome = rcLayout:createButton(rcLayout.sizeX - 41, 11, 12, 1, colors.purple, colors.white, "SET HOME")

    function controls.setHome:onDrop()
        ui:func(function ()
            if gui.yesno(screen, nil, nil, "are you sure you want to set this point as the home point for the drone?") then
                deviceSend(controlAddress, "rc_fexec", "ox, oy, oz = nil, nil, nil")
                mdx, mdy, mdz = 0, 0, 0
            end
        end)
    end

    

    controls.move1 = rcLayout:createButton(5, 5, 4, 1, colors.purple, colors.white, "+Z")
    function controls.move1:onDrop()
        droneMove(0, 0, currentBlockCount)
    end
    controls.move2 = rcLayout:createButton(8, 6, 4, 1, colors.purple, colors.white, "-X")
    function controls.move2:onDrop()
        droneMove(-currentBlockCount, 0, 0)
    end
    controls.move3 = rcLayout:createButton(5, 7, 4, 1, colors.purple, colors.white, "-Z")
    function controls.move3:onDrop()
        droneMove(0, 0, -currentBlockCount)
    end
    controls.move4 = rcLayout:createButton(2, 6, 4, 1, colors.purple, colors.white, "+X")
    function controls.move4:onDrop()
        droneMove(currentBlockCount, 0, 0)
    end
end

local function createRobotControl()
    
end

function rcLayout:onSelect(devicetype)
    for _, object in pairs(controls) do
        object:destroy()
    end
    controls = {}

    local firmwareUpdater = [[local code = ...
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
    return true, true
end
return true]]
    if select(2, assert(select(2, assert(deviceRequest(controlAddress, "rc_exec", firmwareUpdater, assert(fs.readFile(firmwarePath))))))) then
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
        colorpic.disabledHidden = false
        colorpic:setColor(0xffffff)
    end

    blockPeerMove.value = 0
    deviceTypeTitle.text = "device type: " .. devicetype

    offsetTitle.disabledHidden = true
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
        offsetTitle.disabledHidden = false
        for i, v in ipairs(statuses) do
            v.disabledHidden = false
        end

        currentBlockCount = 1
        currentAcceleration = 1
        maxAcceleration = select(2, assert(deviceRequest(controlAddress, "rc_exec", "return drone.setAcceleration(math.huge)")))
        acceleration.value = math.map(1, 0, maxAcceleration, 0, 1)
        blockPeerMoveTextUpdate(true)
        accelerationTextUpdate(true)
        statsUpdate(true)
        createDroneControl()
    else
        for i, v in ipairs(statuses) do
            v.disabledHidden = true
        end
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

ui:loop()
if controlAddress then
    statusRequest(controlAddress, "rc_out")
end