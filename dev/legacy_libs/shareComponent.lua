--WORK IN PROCESS

local likenet = require("likenet")
local event = require("event")
local dport = 572
local tag = "sc_"
local shareComponent = {}

function shareComponent.share(proxy, password, devices, port, echoMode)
    checkArg(1, proxy, "table", "nil")
    checkArg(2, password, "string", "nil")
    checkArg(3, devices, "table", "nil")
    checkArg(4, port, "number", "nil")
    checkArg(5, echoMode, "boolean", "nil")

    local obj = {}
    obj.name = tag .. proxy.type .. proxy.address:sub(1, 5)
    obj.host = likenet.create(obj.name, password, devices, port or dport, echoMode)

    obj.listen = event.listen("client_package", function(_, host, client, requestType, ...)
        if host == obj.host then
            local args = {...}
            if requestType == "call" then
                local result = {pcall(proxy[args[1]], table.unpack(args[2]))}
                if result[1] then
                    obj.host.sendToClient(client, "successfully", table.unpack(result, 2))
                else
                    obj.host.sendToClient(client, "error", result[2])
                end
            elseif requestType == "list" then
                local list = {}
                for name, value in pairs(proxy) do
                    if type(value) == "function" then
                        list[name] = "sc_func"
                    else
                        list[name] = value
                    end
                end
                obj.host.sendToClient(client, "list", list)
            end
        end
    end)

    function obj.destroy()
        event.cancel(obj.listen)
        obj.host.destroy()
    end

    return obj
end

function shareComponent.connect(host, password, port)
    checkArg(1, host, "table", "nil")
    checkArg(2, password, "string", "nil")
    checkArg(3, port, "number", "nil")

    local obj = {}
    obj.proxy = {}
    obj.waiting = true
    obj.client = likenet.connect(host, password, nil, port or dport)
    obj.listen = event.listen("server_package", function(_, client, host, responseType, ...)
        if client == obj.client then
            local args = {...}
            if responseType == "list" then
                for name, value in pairs(args[1]) do
                    if value == "sc_func" then
                        obj.proxy[name] = function (...)
                            
                            return 
                        end
                    else
                        obj.proxy[name] = value
                    end
                    
                end
                obj.waiting = nil
            end
        end
    end)

    function obj.destroy()
        event.cancel(obj.listen)
        obj.client.destroy()
    end

    obj.client.sendToServer("list")

    while obj.waiting do
        event.sleep()
    end

    return obj
end

function shareComponent.list(port)
    local list = {}
    for _, clientData in ipairs(likenet.list(port or dport)) do
        if clientData.name:sub(1, #tag) == tag then
            table.insert(list, clientData)
        end
    end
    return list
end

return shareComponent