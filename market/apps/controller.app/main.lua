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

local screen = ...
local firmwarePath = system.getResourcePath("firmware/rc_bios/code.lua")
local port = 38710
local ui = uix.manager(screen)
local rx, ry = ui:zoneSize()
local modem = component.proxy(utils.findModem(true) or "")
local tunnels = {}
local allModems = {}
local controlAddress
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

local layout = ui:create("controller", uix.colors.black)

local warnMsg
if not modem then
    warnMsg = layout:createText(2, layout.sizeY - 1, uix.colors.red, "the modem was not found! install a modem to use the app")
elseif not modem.isWireless() then
    warnMsg = layout:createText(2, layout.sizeY - 1, uix.colors.orange, "only a wired modem was found")
end

local connectList = layout:createCustom(layout:customCenter(0, -4, gobjs.checkboxgroup, 50, 10))
layout:createVText(layout.sizeX / 2, connectList.y - 1, uix.colors.white, "list of devices")
connectList.oneSelect = true

local passwordInput = layout:createInput(layout:centerOneSize(0, 2, 32, nil, nil, "*", nil, nil, nil, "password: "))
local connectButton = layout:createButton(layout:center(-6, 5, 16, 3, uix.colors.white, uix.colors.gray, "connect"))
local refreshButton = layout:createButton(layout:center(8, 5, 9, 3, uix.colors.orange, uix.colors.white, "refresh"))
local wakeAllButton = layout:createButton(2, layout.sizeY - 1, 10, 1, uix.colors.orange, uix.colors.white, "wake all")

if warnMsg then
    wakeAllButton.y = wakeAllButton.y - 1
end
for tunnel in pairs(tunnels) do
    if warnMsg then
        warnMsg.y = warnMsg.y - 1
    end
    wakeAllButton.y = wakeAllButton.y - 1
    layout:createText(2, layout.sizeY - 1, uix.colors.cyan, "a tunnel card has been found, it can be used to connect to the robot")
    break
end

local function deviceRequest(address, ...)
    local startWaitTime = computer.uptime()
    if tunnels[address] then
        component.invoke(address, "send", ...)
        while computer.uptime() - startWaitTime < 5 do
            local eventData = {event.pull(0.5, "modem_message", address, nil, nil, nil, "rc_tunnel")}
            if eventData[1] then
                return table.unpack(eventData, 7)
            end
        end
    else
        if modem then
            modem.send(address, port, ...)
        end
        while computer.uptime() - startWaitTime < 5 do
            local eventData = {event.pull(0.5, "modem_message", modem.address, address, port)}
            if eventData[1] and eventData[6] ~= "rc_adv" then
                return table.unpack(eventData, 6)
            end
        end
    end
    ui:func(gui.warn, screen, nil, nil, "no response was received")
end

function wakeAllButton:onClick()
    sendAll("rc_wake")
    layout:timer(1, advRequest, 1)
end

local function connect()
    local obj
    for i = 1, #connectList.list do
        if connectList.list[i][2] then
            obj = connectList.list[i]
        end
    end

    if obj then
        ui:fullStop()
        gui.status(screen, nil, nil, "connection attempt...")
        local ret = deviceRequest(obj[3], "rc_connect", passwordInput.read.getBuffer())
        if ret == true then
            passwordInput.read.setBuffer("")
            controlAddress = obj[3]
            rcLayout:select(obj[3])
        else
            ui:forceDraw()
            gui.warn(screen, nil, nil, "incorrect password")
        end
        ui:fullStart()
        ui:draw()
    else
        ui:func(gui.warn, screen, nil, nil, "first, select the device you want to control from the list")
    end
end

connectButton.onClick = connect
passwordInput.onTextAcceptedCheck = connect

function refreshButton:onClick()
    advRequest()
    connectList.list = {}
    connectList:draw()
end

function layout:onSelect()
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
        else
            addTitle = " | distance: " .. math.roundTo(dist, 1)
        end
        local tbl = {v2 .. " " .. v3 .. " " .. sender:sub(1, 6) .. addTitle, false, writeAddr, not isTunnel and computer.uptime()}
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

local infoLayout = ui:create("controller [INFO]", uix.colors.black)
infoLayout:createText(2, 2, uix.colors.white, gui_container.chars.dot .. " to use, flash the EEPROM of the robot/drone with the \"RC Bios\" firmware through the settings>eeprom", rx - 2)
infoLayout:createText(2, 4, uix.colors.white, gui_container.chars.dot .. " if the robot has a screen and a video card, a random 8-character password will be set on it and it will be displayed on the screen", rx - 2)
infoLayout:createText(2, 6, uix.colors.white, gui_container.chars.dot .. " if the robot does not have a screen and/or a video card, then by default it will not have a password", rx - 2)
infoLayout:createText(2, 8, uix.colors.white, gui_container.chars.dot .. " there is always a screen on the drone and therefore a password will be set for the drone in any case", rx - 2)
infoLayout:createText(2, 10, uix.colors.white, gui_container.chars.dot .. " the password will be generated randomly every time you start unless you set your password", rx - 2)
infoLayout:createText(2, 12, uix.colors.white, gui_container.chars.dot .. " in fact, the \"RC Bios\" can be installed on any device, be it a computer or a microcontroller", rx - 2)
infoLayout:createText(2, 14, uix.colors.white, gui_container.chars.dot .. " if a password is not set on the device and a random temporary one cannot be generated (due to the lack of a screen or GPU), then you cannot connect to the device from a distance of more than 8 blocks", rx - 2)
layout:setReturnLayout(infoLayout, uix.colors.green, " INFO ")
infoLayout:setReturnLayout(layout)

-----------------------------

rcLayout = ui:create("controller [Remote Control]", uix.colors.black)
rcLayout:setReturnLayout(layout)

local switchTitle = rcLayout:createText(2, rcLayout.sizeY - 1, uix.colors.white, "allow remote wake-up")
local wakeUpSwitch = rcLayout:createSwitch(switchTitle.x + unicode.len(switchTitle.text) + 1, rcLayout.sizeY - 1)
local colorpic = rcLayout:createColorpic(2, rcLayout.sizeY - 3, 13, 1, "light color", 0xffffff, true)
local randPass = rcLayout:createButton(2, rcLayout.sizeY - 7, 21, 1, "use random password", 0xffffff, true)
local customPass = rcLayout:createButton(2, rcLayout.sizeY - 5, 21, 1, "use custom password", 0xffffff, true)

function randPass:onClick()
    deviceRequest(controlAddress, "rc_exec", "component.invoke(component.list('eeprom')(), 'set', '')")
end

function customPass:onClick()
    local password = gui.comfurmPassword(screen)
    if password then
        deviceRequest(controlAddress, "rc_exec", "component.invoke(component.list('eeprom')(), 'set', ...)", hash(password))
    end
    ui:draw()
end

function colorpic:onColor(_, color)
    deviceRequest(controlAddress, "rc_exec", "setColor(" .. color .. ")")
end

function rcLayout:onUnselect()
    deviceRequest(controlAddress, "rc_out")
    controlAddress = nil
end

function rcLayout:onSelect()
    deviceRequest(controlAddress, "rc_exec", [[
        local code = ...
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
    ]], assert(fs.readFile(firmwarePath)))
    wakeUpSwitch.state = not not select(2, assert(deviceRequest(controlAddress, "rc_exec", "return (tunnel and tunnel.getWakeMessage() == \"rc_wake\") or (modem and modem.getWakeMessage() == \"rc_wake\")")))
end

function wakeUpSwitch:onSwitch()
    if self.state then
        deviceRequest(controlAddress, "rc_exec", [[
            if tunnel then
                tunnel.setWakeMessage("rc_wake")
            end

            if modem then
                modem.setWakeMessage("rc_wake")
            end
        ]])
    else
        deviceRequest(controlAddress, "rc_exec", [[
            if tunnel then
                tunnel.setWakeMessage()
            end

            if modem then
                modem.setWakeMessage()
            end
        ]])
    end
end

ui:loop()
if controlAddress then
    deviceRequest(controlAddress, "rc_out")
end