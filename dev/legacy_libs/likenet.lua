--WORK IN PROCESS

local event = require("event")
local component = require("component")
local computer = require("computer")

--------------------------------------------

local likenet = {}
likenet.port = 432
likenet.maxPackageSize = 1024 * 7 --в opencomputers есть служебная информация, по этому я выделел для нее 1кб
likenet.servers = {}
likenet.clients = {}

function likenet.packageToParts(...)
    return toParts(serialization({...}), likenet.maxPackageSize)
end

function likenet.getDevices()
    local devices = {}
    for address in pairs(component.list("modem")) do
        devices[address] = true
    end
    for address in pairs(component.list("tunnel")) do
        devices[address] = true
    end
    return devices
end

function likenet.create(name, password, devices, port, echoMode)
    checkArg(1, name, "string", "nil")
    checkArg(2, password, "string", "nil")
    checkArg(3, devices, "table", "nil")
    checkArg(4, port, "number", "nil")
    checkArg(5, echoMode, "boolean", "nil")

    name = name or ("server_" .. computer.address())
    password = password or "0000"
    devices = devices or likenet.getDevices()
    local lport = port or likenet.port

    ------------------------------------

    for device in pairs(devices) do
        if component.type(device) == "modem" then
            component.invoke(device, "open", lport)
        end
    end

    local function raw_send(client, ...)
        if client.deviceType == "modem" then
            return component.invoke(client.device, "send", client.address, lport, ...)
        else
            return component.invoke(client.device, "send", ...)
        end
    end

    ------------------------------------

    local host = {}
    host.clients = {}
    host.echoMode = not not echoMode

    --вернет таблицу обектов клиентов в формате {{name = "clientname", deviceType == "modem"/"tunnel", device = "address", address = "address", connected = true}}, для передачи данных клиенту нужно будет передавать в функцию sendToClient обект из этой таблицы
    function host.getClients() 
        return host.clients
    end

    function host.sendToClient(client, ...)
        if not client.connected and client.disconnected then return nil, "client disconnected" end

        if not client.connected then
            client.disconnected = true
            raw_send(client, "disconnected")
            return
        end

        local smallPackages = likenet.packageToParts(...)
        local id = math.random(0, 9999)
        for index, packagePart in ipairs(smallPackages) do
            if not raw_send(client, (index == #smallPackages) and "package" or "packagePart", id, packagePart) then
                return nil, "unknown error"
            end
        end
    end

    function host.sendToClients(...)
        for i, client in ipairs(host.getClients()) do
            host.sendToClient(client, ...)
        end
    end

    function host.disconnect(client) --отключает переданого клиента, вернет true если клиент был отключен
        for i, lclient in ipairs(host.clients) do
            if lclient == client then
                client.connected = false
                host.sendToClient(client)
                table.remove(host.clients, i)
                return true
            end
        end
        return false
    end

    ------------------------------------

    function host.destroy() --вырубает хост
        event.cancel(host.listen)
        event.cancel(host.timer)
        
        for i, client in ipairs(host.getClients()) do
            client:disconnect()
        end

        for i, sv in ipairs(likenet.servers) do
            if sv == host then
                table.remove(likenet.servers, i)
                break
            end
        end
    end

    function host.echo()
        for device in pairs(devices) do
            if component.type(device) == "modem" then
                component.invoke(device, "broadcast", lport, "host", name)
            elseif component.type(device) == "tunnel" then
                component.invoke(device, "send", "host", name)
            end
        end
    end

    local cache = {}

    host.listen = event.listen("modem_message", function(_, modemAddress, clientModemAddress, port, dist, packageType, ...)
        local args = {...}
        
        if type(modemAddress) == "string" and devices[modemAddress] and (port == 0 or port == lport) then
            local deviceType = component.type(modemAddress)

            if deviceType == "modem" or deviceType == "tunnel" then
                if packageType == "connect" then
                    local function sendResult(...)
                        if deviceType == "modem" then
                            component.invoke(modemAddress, "send", clientModemAddress, lport, ...)
                        else
                            component.invoke(modemAddress, "send", ...)
                        end
                    end
                    if args[2] == password then
                        for i, client in ipairs(host.getClients()) do
                            if client.address == clientModemAddress then
                                sendResult("connectResult", false, "you are already connected")
                                return
                            end
                        end
                        table.insert(host.clients, {
                            host = host,
                            name = args[1],
                            address = clientModemAddress,
                            device = modemAddress,
                            deviceType = deviceType,
                            connected = true,
                            disconnect = host.disconnect,
                            sendToClient = host.sendToClient,
                        })
                        sendResult("connectResult", true)
                    else
                        sendResult("connectResult", false, "invalid password")
                    end
                elseif packageType == "clientDisconnect" then
                    for i, client in ipairs(host.getClients()) do
                        if client.address == clientModemAddress then
                            host.disconnect(client)
                            break
                        end
                    end
                elseif packageType == "clientPackage" then
                    local client
                    for i, lclient in ipairs(host.getClients()) do
                        if lclient.address == clientModemAddress then
                            client = lclient
                            break
                        end
                    end
                    
                    if client then
                        cache[args[1]] = (cache[args[1]] or "") .. args[2]

                        local result = {pcall(unserialization, cache[args[1]])}
                        if result[1] then
                            event.push("client_package", host, client, table.unpack(result[2])) --likeOS поддерживает передачу таблиц через event
                        end

                        cache[args[1]] = nil
                    end
                elseif packageType == "clientPackagePart" then
                    local client
                    for i, lclient in ipairs(host.getClients()) do
                        if lclient.address == clientModemAddress then
                            client = lclient
                            break
                        end
                    end
                    
                    if client then
                        cache[args[1]] = (cache[args[1]] or "") .. args[2]
                    end
                end
            end
        end
    end)
    host.timer = event.timer(1, function()
        if not host.echoMode then return end
        host.echo()
    end, math.huge)

    table.insert(likenet.servers, host)
    return host
end

--выведет список доступных сетей для подключения в формате {{name = "name", serverDevice = "address", clientDevice = "address"}
--этот обект нужно будет передать в функцию подключения к сети
function likenet.list(port)
    local list = {}
    local lport = port or likenet.port

    for address in component.list("modem") do
        component.invoke(address, "open", lport)
    end

    local lastpackage = computer.uptime()
    while computer.uptime() - lastpackage <= 2 do
        local eventData = {event.pull(0.1)}
        
        if eventData[1] == "modem_message" and type(eventData[2]) == "string" and
        (component.type(eventData[2]) == "modem" or component.type(eventData[2]) == "tunnel") and
        (eventData[4] == 0 or eventData[4] == lport) and eventData[6] == "host" and
        type(eventData[7]) == "string" then

            local finded
            for i, v in ipairs(list) do
                if v.serverDevice == eventData[3] then
                    finded = true
                    break
                end
            end

            if not finded then
                lastpackage = computer.uptime()
                table.insert(list, {
                    name = eventData[6],
                    serverDevice = eventData[3],
                    clientDevice = eventData[2],
                })
            end
        end
    end

    return list
end

--подключаеться к сети используя обьект полученый из функции list
function likenet.connect(host, password, connectingName, port)
    checkArg(1, host, "table", "nil")
    checkArg(2, password, "string", "nil")
    checkArg(3, connectingName, "string", "nil")
    checkArg(4, port, "number", "nil")

    local lport = port or likenet.port
    host = host or likenet.list(lport)[1]
    password = password or "0000"
    connectingName = connectingName or ("client_" .. computer.address())
    
    ------------------------------------

    local function raw_send(...)
        if component.type(host.clientDevice) == "tunnel" then
            component.invoke(host.clientDevice, "send", ...)
        else
            component.invoke(host.clientDevice, "send", host.serverDevice, lport, ...)
        end
    end

    local function isValidPackage(eventData)
        return eventData[1] == "modem_message" and type(eventData[2]) == "string" and (component.type(eventData[2]) == "modem" or component.type(eventData[2]) == "tunnel") and (eventData[4] == 0 or eventData[4] == lport)
    end

    local function wait_result(packageType)
        local starttime = computer.uptime()
        while computer.uptime() - starttime <= 2 do
            local eventData = {event.pull(0.1)}
            if isValidPackage(eventData) and (not packageType or eventData[6] == packageType) then
                return table.unpack(eventData, 6)
            end
        end
    end

    raw_send("connect", connectingName, password)
    local packageType, state, err = wait_result("connectResult")

    if not packageType then
        return nil, "connection error"
    end

    if not state then
        return nil, err or "unknown error"
    end

    ------------------------------------

    local client = {}
    client.connected = true
    client.host = host

    local function disconnect()
        event.cancel(client.listen)
        client.connected = false
        event.push("disconnected", client, host)

        for i, cl in ipairs(likenet.clients) do
            if cl == client then
                table.remove(likenet.clients, i)
                break
            end
        end
    end

    function client.sendToServer(...) --отправляет херню на сервер
        local smallPackages = likenet.packageToParts(...)
        local id = math.random(0, 9999)
        for index, packagePart in ipairs(smallPackages) do
            if not raw_send((index == #smallPackages) and "clientPackage" or "clientPackagePart", id, packagePart) then
                return nil, "unknown error"
            end
        end
    end

    function client.destroy() --удаляет клиент
        raw_send("clientDisconnect")
        disconnect()
    end

    local cache = {}

    client.listen = event.listen("modem_message", function(...)
        if not client.connected then return false end

        local args = {...}
        if isValidPackage(args) then
            local packageType, id, content = args[6], args[7], args[8]

            if packageType == "disconnected" then
                disconnect()
            elseif packageType == "packagePart" then
                cache[id] = (cache[id] or "") .. content
            elseif packageType == "package" then
                cache[id] = (cache[id] or "") .. content

                local result = {pcall(unserialization, cache[id])}
                if result[1] then
                    event.push("server_package", client, host, table.unpack(result[2]))
                end

                cache[id] = nil
            end
        end
    end)

    return client
end

return likenet