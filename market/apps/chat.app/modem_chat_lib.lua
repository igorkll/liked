local component = require("component")
local event = require("event")

local function openPort(addr, port)
    if component.invoke(addr, "open", port) == nil then --если не удалось открыть порт потому что их было дохрена открыто
        component.invoke(addr, "close")
        component.invoke(addr, "open", port)
    end
end

local port = 898
for address in component.list("modem") do
    openPort(address, port)
end

--packed == messageUuid, dist, partNumber, maxPartNumber, part

------------------------------------

local messagesUuidBlackList = {}
local messagesPartBuffer = {}

local function send(messageUuid, dist, ignoreDevice, ...)
    local messageUuid = messageUuid or uuid()
    local dist = dist or 0

    local message = toParts(serialization({...}), 7000)
    local parts = #message

    local function sendPart(ignoreDevice, partNumber, maxPartNumber, part)
        for address in component.list("modem") do
            if address ~= ignoreDevice then
                openPort(address, port)
                local strengthSetted, strength = pcall(component.invoke, address, "setStrength", math.huge)
                component.invoke(address, "broadcast", port, "modem_chat_lib", messageUuid, dist, partNumber, maxPartNumber, part)
                if strengthSetted then
                    component.invoke(address, "setStrength", strength)
                end
            end
        end

        for address in component.list("tunnel") do
            if address ~= ignoreDevice then
                component.invoke(address, "send", "modem_chat_lib", messageUuid, dist, partNumber, maxPartNumber, part)
            end
        end
    end
    
    for i, v in ipairs(message) do
        sendPart(ignoreDevice, i, parts, v)
    end

    return messageUuid
end

local function checkMessageParts(message)
    local count = 0
    for k, v in pairs(message) do
        --event.errLog(type(k))
        if type(k) == "number" then
            --computer.beep(2000, 0.001)
            count = count + 1
        end
    end
    --computer.beep((count + 1) * 100, 0.1)
    return count
end

local function checkFullMessages()
    for k, v in pairs(messagesPartBuffer) do
        if checkMessageParts(v) == v.parts then
            --computer.beep(1000, 0.1)
            messagesUuidBlackList[k] = true
            messagesPartBuffer[k] = nil
            send(k, v.dist, v.black, table.unpack(unserialization(table.concat(v))))
            --computer.beep(2000, 0.5)
            event.push("raw_chat_message", v.dist, table.unpack(unserialization(table.concat(v))))
        end
    end
end

------------------------------------

event.listen("modem_message", function(_, deviceUuid, _, lport, dist, messageLabel, messageUuid, sendedDist, partNumber, maxPartNumber, part)
    if not _G.chat_allow then return end
    if (lport == port or lport == 0) and messageLabel == "modem_chat_lib" and not messagesUuidBlackList[messageUuid] then
        --computer.beep(2000, 0.1)
        local mathDist = dist + sendedDist

        if not messagesPartBuffer[messageUuid] then
            messagesPartBuffer[messageUuid] = {}
        end
        messagesPartBuffer[messageUuid][partNumber] = part
        if lport == 0 or not component.invoke(deviceUuid, "isWireless") then
            messagesPartBuffer[messageUuid].black = deviceUuid
        end
        messagesPartBuffer[messageUuid].parts = maxPartNumber
        messagesPartBuffer[messageUuid].dist = mathDist

        checkFullMessages()
    end
end)

return {
    send = function(...)
        messagesUuidBlackList[send(nil, nil, nil, ...)] = true
    end
}