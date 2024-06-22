local computer, component = computer, component
modem = component.proxy(component.list("modem")() or "")
tunnel = component.proxy(component.list("tunnel")() or "")

local port = 38710
local wakeMsg = "rc_wake"

if modem then
    pcall(modem.setStrength, math.huge)
    modem.close()
    modem.open(port)
end

drone = component.proxy(component.list("drone")() or "")
robot = component.proxy(component.list("robot")() or "")
local devicename
local gpu = component.proxy(component.list("gpu")() or "")
local eeprom = component.proxy(component.list("eeprom")() or "")
local screen = component.list("screen")()
if gpu and screen then
    gpu.bind(screen)
    gpu.setResolution(10, 2)
else
    gpu = nil
end

if drone then
    devicename = drone.name()
elseif robot then
    devicename = robot.name()
end

function setWake(state)
    if state then
        if tunnel then
            tunnel.setWakeMessage(wakeMsg)
        end
        
        if modem then
            modem.setWakeMessage(wakeMsg)
        end
    else
        if tunnel then
            tunnel.setWakeMessage()
        end
        
        if modem then
            modem.setWakeMessage()
        end
    end
end

function setColor(color)
    local obj = drone or robot
    if obj then
        obj.setLightColor(color)
    end
end
currentColor = 0xffffff
setColor(currentColor)

function setText(text)
    if drone then
        drone.setStatusText(text)
        return 1
    elseif gpu then
        local rx, ry = gpu.getResolution()
        gpu.setBackground(0)
        gpu.setForeground(0xffffff)
        gpu.fill(1, 1, rx, ry, " ")
        local line = 1
        local index = 1
        for i = 1, #text do
            local char = text:sub(i, i)
            if char == "\n" then
                line = line + 1
                index = 1
            else
                gpu.set(index, line, char)
                index = index + 1
            end
        end
        return 1
    end
end
local screenOk = setText("")

local devicetype
do
    local deviceinfo = computer.getDeviceInfo()

    local function isType(ctype)
        return component.list(ctype)() and ctype
    end
    
    local function isServer()
        local obj = deviceinfo[computer.address()]
        if obj and obj.description and obj.description:lower() == "server" then
            return "server"
        end
    end
    
    devicetype = isType("tablet") or isType("microcontroller") or isType("drone") or isType("robot") or isServer() or isType("computer") or "unknown"
end

----------------------------------------------

local randomPassword
local passwordHash = eeprom.getData()
if #passwordHash == 0 then
    passwordHash = nil
end

local function passText()
    if screenOk then
        if passwordHash then
            setText("password\nchanged")
        else
            randomPassword = ""
            for i = 1, 8 do
                randomPassword = randomPassword .. string.char(math.random(33, 126))
            end
            setText("password:\n" .. randomPassword)
        end
    end
end
passText()

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

local function checkPassword(password)
    if passwordHash then
        return hash(password) == passwordHash
    elseif randomPassword then
        return password == randomPassword
    else
        return true
    end
end

local function send(isTunnel, address, ...)
    if isTunnel then
        tunnel.send("rc_tunnel", ...)
    else
        modem.send(address, port, ...)
    end
end

if tunnel then
    tunnel.send("rc_adv", devicetype, devicename)
end

local oldAdvTime = -math.huge
local currentUser
local isTunnel
while true do
    local eventData = {computer.pullSignal(0.5)}

    if currentUser then
        if eventData[1] == "modem_message" and eventData[3] == currentUser then
            local cmd, arg = eventData[6], eventData[7]
            if cmd == "rc_exec" then
                local code, err = load(arg)
                if code then
                    send(isTunnel, currentUser, pcall(code, table.unpack(eventData, 8)))
                else
                    send(isTunnel, currentUser, false, err)
                end
            elseif cmd == "rc_color" then
                currentColor = arg
                setColor(currentColor)
            elseif cmd == "rc_title" then
                setText(arg)
            elseif cmd == "rc_out" then
                currentColor = 0xffffff
                setColor(currentColor)
                passText()
                computer.beep(200, 0.2)
                computer.beep(150, 0.2)
                computer.beep(100, 0.8)
                send(isTunnel, currentUser, true)
                currentUser = nil
            end
        end
    else
        if eventData[1] == "modem_message" then
            local sender = eventData[3]
            isTunnel = tunnel and eventData[2] == tunnel.address
            if eventData[6] == "rc_radv" then
                if modem then
                    modem.send(sender, port, "rc_adv", devicetype, devicename)
                end
                if tunnel then
                    tunnel.send("rc_adv", devicetype, devicename)
                end
            elseif eventData[6] == "rc_connect" and (randomPassword or passwordHash or eventData[5] <= 8) then
                if checkPassword(eventData[7]) then
                    setColor(0x00ff00)
                    computer.beep(1800, 0.05)
                    computer.beep(1800, 0.05)
                    setColor(currentColor)
                    send(isTunnel, sender, true)
                    currentUser = sender
                    setText("")
                else
                    setColor(0xff0000)
                    computer.beep(100, 0.1)
                    computer.beep(100, 0.1)
                    setColor(currentColor)
                    send(isTunnel, sender, false)
                end
            end
        end

        if modem then
            local uptime = computer.uptime()
            if uptime - oldAdvTime > 3 then
                if not randomPassword and not passwordHash then
                    pcall(modem.setStrength, 8)
                end
                modem.broadcast(port, "rc_adv", devicetype, devicename)
                pcall(modem.setStrength, math.huge)
                oldAdvTime = uptime
            end
        end
    end
end