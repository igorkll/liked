local modem = component.proxy(component.list("modem")() or "")
local tunnel = component.proxy(component.list("tunnel")() or "")

local port = 38710

if tunnel then
    tunnel.setWakeMessage("wake")
end

if modem then
    modem.close()
    modem.open(port)
    modem.setWakeMessage("wake")
    pcall(modem.setStrength, math.huge)
end

drone = component.proxy(component.list("drone")() or "")
robot = component.proxy(component.list("robot")() or "")
local devicename = "unknown"
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

local function setColor(color)
    local obj = drone or robot
    if obj then
        obj.setLightColor(color)
    end
end
local currentColor = 0xffffff
setColor(currentColor)

local function setText(text)
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
                gpu.set(index, line, text)
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
    if randomPassword then
        return password == randomPassword
    elseif passwordHash then
        return hash(password) == passwordHash
    else
        return true
    end
end

local function advSend()
    modem.broadcast(port, "rc_adv", devicetype)
end

local oldAdvTime = -math.huge
local currentUser
while true do
    if not currentUser then
        local uptime = computer.uptime()
        if uptime - oldAdvTime > 3 then
            if modem then
                if not randomPassword and not passwordHash then
                    pcall(modem.setStrength, 8)
                end
                advSend()
                pcall(modem.setStrength, math.huge)
            end
            oldAdvTime = uptime
        end
    end
    local eventData = {computer.pullSignal(0.5)}
    if eventData[1] == "modem_message" and eventData[2] == modem.address then
        if eventData[6] == "rc_radv" then
            advSend()
        elseif not currentUser and eventData[6] == "rc_connect" and (randomPassword or passwordHash or eventData[5] <= 8) then
            if checkPassword(eventData[7]) then
                setColor(0x00ff00)
                computer.beep(1800, 0.05)
                computer.beep(1800, 0.05)
                setColor(currentColor)
                modem.send(eventData[3], port, true)
                currentUser = eventData[3]
            else
                setColor(0xff0000)
                computer.beep(100, 0.1)
                computer.beep(100, 0.1)
                setColor(currentColor)
                modem.send(eventData[3], port, false)
            end
        end
    end
end