local modem
for address in component.list("modem", true) do
    if component.invoke(address, "isWireless") then
        if component.invoke(address, "setStrength", math.huge) >= 400 then
            modem = address
            break
        end
    end
end
if not modem then
    modem = component.list("modem", true)()
    if not modem then
        error("the modem was not found", 0)
    end
end
modem = component.proxy(modem)

local port = 38710
modem.close()
modem.open(port)

drone = component.proxy(component.list("drone")() or "")
robot = component.proxy(component.list("robot")() or "")
gpu = component.proxy(component.list("gpu")() or "")
screen = component.list("screen")()
if gpu and screen then
    gpu.bind(screen)
else
    gpu = nil
end

local function setColor(color)
    (drone or robot).setLightColor(color)
end

local function setText(text)
    if drone then
        drone.setStatusText(text)
    elseif gpu then
        
    end
end

local function getDeviceType()
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
    
    return isType("tablet") or isType("microcontroller") or isType("drone") or isType("robot") or isServer() or isType("computer") or "unknown"
end

----------------------------------------------

local randomPassword

while true do
    local eventData = {computer.pullSignal(0.5)}
    if eventData[1] == "modem_message" and eventData[2] == modem.address then
        
    end
end