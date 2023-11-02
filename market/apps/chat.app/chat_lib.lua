--[[
    протол:

    чат пакет:
    1. загаловок likedChatMessage
    2. ник отправителя
    3. цвет ника отправителя
    4. тип сообщения, может быть: text/image/file
    5. само сообщения

    event сообщения чата:
    1. загаловок chat_message
    2. ник отправителя
    3. цвет ника отправителя
    4. тип сообщения, может быть: text/image/file
    5. само сообщения
    6. разтояния с которого сообщения было отправленно
]]

local computer = require("computer")
local component = require("component")
local event = require("event")
local fs = require("filesystem")
local modem_chat_lib = require("modem_chat_lib", true)

local function checkHistory()
    local file = fs.open("/data/bin/chat.app/history.dat", "rb")
    local historyDat = file.readAll()
    file.close()

    local history = split(historyDat, "\n")

    while #history > 64 do
        table.remove(history, 1)
    end

    local file = fs.open("/data/bin/chat.app/history.dat", "wb")
    file.write(table.concat(history, "\n"))
    file.close()
end

local function addToHistory(...)
    local messageToSave = assert(serialization({...}))

    local file = fs.open("/data/bin/chat.app/history.dat", "ab")
    file.write(messageToSave .. "\n")
    file.close()
    checkHistory()
end

local function send(...)
    addToHistory(...)
    modem_chat_lib.send("likedChatMessage", ...)
end

local function beep(f, d)
    local beepcard = component.list("beep")()
    if beepcard then
        component.invoke(beepcard, "beep", {[f] = d})
    else
        computer.beep(f, d)
    end
end

event.listen("raw_chat_message", function(_, dist, label, nikname, color, messageType, message)
    if not _G.chat_allow then return end
    if label == "likedChatMessage" then
        dist = math.floor(dist + 0.5)

        if messageType == "text" then
            beep(700, 0.2)
        elseif messageType == "image" then
            beep(2000, 0.2)
        elseif messageType == "file" then
            beep(1500, 0.2)
        end

        addToHistory(nikname, color, messageType, message, dist)
        event.push("chat_message", nikname, color, messageType, message, dist)
    end
end)

------------------------------------

return {
    send = send,
    checkHistory = checkHistory
}