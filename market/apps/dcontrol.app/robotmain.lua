local likenet = require("likenet")
local component = require("component")
local event = require("event")
local robot = component.proxy(component.list("robot")())

local server = likenet.create("dcontrol_robot", "584")

while true do
    local clients = server.getClients()
    server.echoMode = #clients == 0
    if #clients > 1 then
        for i = 2, #clients do
            clients[i]:disconnect()
        end
    end
    

    local eventData = {event.pull()}
    if eventData[1] == "server_package" and eventData[2] == server then
        
    end
end