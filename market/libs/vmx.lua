local component = require("component")
local computer = require("computer")
local unicode = require("unicode")
local natives = require("natives")
local fs = require("filesystem")
local text = require("text")
local uuid = require("uuid")
local thread = require("thread")
local graphic = require("graphic")
local screensaver = require("screensaver")
local sysinit = require("sysinit")
local palette = require("palette")
local lastinfo = require("lastinfo")
local event = require("event")
local vmx = {}

function vmx.createBaseEnv(vm)
    local sandbox
    sandbox = {
        _VERSION = _VERSION,
        
        checkArg = checkArg,
        assert = assert,
        error = error,
        getmetatable = getmetatable,
        setmetatable = setmetatable,
        pairs = pairs,
        ipairs = ipairs,
        next = next,
        pcall = natives.pcall,
        xpcall = natives.xpcall,
        rawequal = rawequal,
        rawget = rawget,
        rawlen = rawlen,
        rawset = rawset,
        select = select,
        tonumber = tonumber,
        tostring = tostring,
        type = type,
        load = function(ld, source, mode, env)
            return load(ld, source, mode, env or sandbox)
        end,

        math = table.deepclone(natives.math),
        table = table.deepclone(natives.table),
        unicode = table.deepclone(unicode),
        string = table.deepclone(string),
        bit32 = table.deepclone(bit32),
        debug = table.deepclone(debug),

        os = {
            clock = os.clock,
            date = os.date,
            time = os.time
        },

        coroutine = {
            create = coroutine.create,
            resume = function(co, ...) -- custom resume part for bubbling sysyields
                checkArg(1, co, "thread")
                local args = table.pack(...)
                while true do -- for consecutive sysyields
                    local result = table.pack(coroutine.resume(co, table.unpack(args, 1, args.n)))
                    if result[1] then -- success: (true, sysval?, ...?)
                        if coroutine.status(co) == "dead" then -- return: (true, ...)
                            return true, table.unpack(result, 2, result.n)
                        elseif result[2] ~= nil then -- yield: (true, sysval)
                            args = table.pack(coroutine.yield(result[2]))
                        else -- yield: (true, nil, ...)
                            return true, table.unpack(result, 3, result.n)
                        end
                    else -- error: result = (false, string)
                        return false, result[2]
                    end
                end
            end,
            running = coroutine.running,
            status = coroutine.status,
            wrap = function(f) -- for bubbling coroutine.resume
                local co = coroutine.create(f)
                return function(...)
                    local result = table.pack(sandbox.coroutine.resume(co, ...))
                    if result[1] then
                        return table.unpack(result, 2, result.n)
                    else
                        error(result[2], 0)
                    end
                end
            end,
            yield = function(...) -- custom yield part for bubbling sysyields
                return coroutine.yield(nil, ...)
            end,
            isyieldable = coroutine.isyieldable
        }
    }

    if _VERSION == "Lua 5.3" or _VERSION == "Lua 5.4" then
        sandbox.bit32 = nil
        sandbox.utf8 = table.deepclone(utf8)
    end

    sandbox._G = sandbox
    return sandbox
end

function vmx.createComputerLib(vm)
    local computerlib, internalComputer
    internalComputer = {
        maxEventsCount = 256,
        events = {},
        pullSignal = function(timeout)
            local deadline = computer.uptime() + (type(timeout) == "number" and timeout or math.huge)
            repeat
                if #internalComputer.events > 0 then
                    return table.unpack(table.remove(internalComputer.events))
                else
                    local signal = table.pack(coroutine.yield(deadline - computer.uptime()))
                    if signal.n > 0 then
                        return table.unpack(signal, 1, signal.n)
                    end
                end
            until computer.uptime() >= deadline
        end,
        pushSignal = function(name, ...)
            if type(name) == "string" then
            elseif type(name) == "number" then
                name = tostring(name)
            else
                checkArg(1, name, "string")
            end
            if #internalComputer.events < internalComputer.maxEventsCount then
                table.insert(internalComputer.events, {name, ...})
                return true
            end
            return false
        end,
        clearQueue = function()
            internalComputer.events = {}
        end
    }
    computerlib = {
        --architecture
        getArchitectures = function()
            return {_VERSION}
        end,
        getArchitecture = function()
            return _VERSION
        end,
        setArchitecture = function(architecture)
            if architecture ~= _VERSION then
                error("unknown architecture", 2)
            end
        end,

        --users
        users = function()
        end,
        removeUser = function()
            return false
        end,
        addUser = function(name)
            error("user must be online", 2)
        end,

        --events
        pushSignal = internalComputer.pushSignal,
        pullSignal = internalComputer.pullSignal,

        --base
        beep = function(...)
            return vm.componentlib.invoke(vm.address, "beep", ...)
        end,
        getDeviceInfo = function()
            return vm.componentlib.invoke(vm.address, "getDeviceInfo")
        end,
        getProgramLocations = function()
            return vm.componentlib.invoke(vm.address, "getProgramLocations")
        end,
        uptime = function()
            if vm.startTime then
                return computer.uptime() - vm.startTime
            end
            return computer.uptime()
        end,
        address = function()
            return vm.address
        end,
        tmpAddress = function()
            return vm.tmpAddress
        end,

        freeMemory = function()
            return computer.freeMemory()
        end,
        totalMemory = function()
            return computer.totalMemory()
        end,

        -- power
        shutdown = function(reboot)
            coroutine.yield(not not reboot)
        end,
        energy = computer.energy,
        maxEnergy = computer.maxEnergy,
    }
    return computerlib, internalComputer
end

local function isFunc(obj)
    if type(obj) == "function" then
        return true
    else
        local mt = getmetatable(obj)
        return not not (mt and mt.__call)
    end
end

function vmx.createComponentLib()
    local componentlib, internalComponent
    internalComponent = {
        components = {},
        proxyCache = setmetatable({}, {__mode = "v"}),
        componentCallback = {
            __call = function(self, ...)
                return componentlib.invoke(self.address, self.name, ...)
            end,
            __tostring = function(self)
                return componentlib.doc(self.address, self.name) or "function"
            end
        },
        componentProxy = {
            __index = function(self, key)
              if self.fields[key] and self.fields[key].getter then
                return componentlib.invoke(self.address, key)
              else
                rawget(self, key)
              end
            end,
            __newindex = function(self, key, value)
              if self.fields[key] and self.fields[key].setter then
                return componentlib.invoke(self.address, key, value)
              elseif self.fields[key] and self.fields[key].getter then
                error("field is read-only")
              else
                rawset(self, key, value)
              end
            end,
            __pairs = function(self)
              local keyProxy, keyField, value
              return function()
                if not keyField then
                  repeat
                    keyProxy, value = next(self, keyProxy)
                  until not keyProxy or keyProxy ~= "fields"
                end
                if not keyProxy then
                  keyField, value = next(self.fields, keyField)
                end
                return keyProxy or keyField, value
              end
            end
        },
        bind = function(tbl)
            internalComponent.components[tbl.address] = tbl
        end,
        unbind = function(tbl)
            internalComponent.components[tbl.address] = nil
        end
    }
    componentlib = {
        doc = function(address, method)
            checkArg(1, address, "string")
            checkArg(2, method, "string")
            local comp = internalComponent.components[address]
            if not comp then
                error("no such component", 2)
            end
            if comp.docs and comp.docs[method] then
                return tostring(comp.docs[method])
            end
        end,
        invoke = function(address, method, ...)
            checkArg(1, address, "string")
            checkArg(2, method, "string")

            local comp = internalComponent.components[address]
            if not comp then
                error("no such component", 2)
            end

            if not isFunc(comp[method]) then
                error("no such method", 2)
            end

            return spcall(comp[method], ...)
        end,
        list = function(filter, exact)
            checkArg(1, filter, "string", "nil")
            local list = {}
            for address, tbl in pairs(internalComponent.components) do
                if not filter or tbl.type == filter or (not exact and tbl.type:find(text.escapePattern(filter))) then
                    list[address] = tbl.type
                end
            end

            local key = nil
            return setmetatable(list, {__call=function()
                key = next(list, key)
                if key then
                    return key, list[key]
                end
            end})
        end,
        methods = function(address)
            checkArg(1, address, "string")
            local comp = internalComponent.components[address]
            if not comp then
                error("no such component", 2)
            end

            local list = {}
            for name, func in pairs(comp) do
                if isFunc(func) then
                    if comp.direct and comp.direct[name] then
                        list[name] = comp.direct[name]
                    else
                        list[name] = true
                    end
                end
            end
            return list
        end,
        type = function(address)
            checkArg(1, address, "string")
            local comp = internalComponent.components[address]
            if not comp then
                error("no such component", 2)
            end
            return comp.type
        end,
        slot = function(address)
            checkArg(1, address, "string")
            local comp = internalComponent.components[address]
            if not comp then
                error("no such component", 2)
            end
            return comp.slot or -1
        end,
        fields = function(address)
            checkArg(1, address, "string")
            local comp = internalComponent.components[address]
            if not comp then
                error("no such component", 2)
            end
            if comp then
                return {}
            end
        end,
        proxy = function(address)
            checkArg(1, address, "string")
            local type, reason = spcall(componentlib.type, address)
            if not type then
                return nil, reason
            end
            local slot, reason = spcall(componentlib.slot, address)
            if not slot then
                return nil, reason
            end
            if internalComponent.proxyCache[address] then
                return internalComponent.proxyCache[address]
            end
            local proxy = {address = address, type = type, slot = slot, fields = {}}
            local methods, reason = spcall(componentlib.methods, address)
            if not methods then
                return nil, reason
            end
            for method in pairs(methods) do
                proxy[method] = setmetatable({address=address,name=method}, internalComponent.componentCallback)
            end
            setmetatable(proxy, internalComponent.componentProxy)
            internalComponent.proxyCache[address] = proxy
            return proxy
        end
    }
    return componentlib, internalComponent
end

function vmx.createVirtualComputer(vm)
    local componentComputer
    componentComputer = {
        type = "computer",
        address = vm.address,

        start = function()
            return false
        end,
        isRunning = function()
            return true
        end,
        stop = function()
            coroutine.yield(false)
        end,
        beep = function(...)
            return spcall(computer.beep, ...)
        end,
        getDeviceInfo = function()
            return table.deepclone(vm.deviceinfo)
        end,
        getProgramLocations = function()
            return spcall(computer.getProgramLocations)
        end
    }
    return componentComputer
end

function vmx.createVirtualEeprom(eepromPath, eepromCodePath, eepromLabelPath)
    eepromCodePath = eepromCodePath or (eepromPath .. ".data")
    eepromLabelPath = eepromLabelPath or (eepromPath .. ".label")

    local maxCodeSize = 1024 * 4
    local maxDataSize = 256
    local maxLabelSize = 24

    local eeprom
    eeprom = {
        type = "eeprom",
        address = uuid.next(),

        -- params
        getSize = function()
            return maxCodeSize
        end,
        getDataSize = function()
            return maxDataSize
        end,

        -- code
        get = function()
            local data = fs.readFile(eepromPath)
            if data then
                return data
            else
                return ""
            end
        end,
        set = function(str)
            if str then
                checkArg(1, str, "string")
                if #str > maxCodeSize then
                    error("not enough space", 2)
                end
                fs.writeFile(eepromPath, str)
            else
                fs.writeFile(eepromPath, "")
            end
        end,

        -- data
        getData = function()
            local data = fs.readFile(eepromCodePath)
            if data then
                return data
            else
                return ""
            end
        end,
        setData = function(str)
            if str then
                checkArg(1, str, "string")
                if #str > maxDataSize then
                    error("not enough space", 2)
                end
                fs.writeFile(eepromCodePath, str)
            else
                fs.writeFile(eepromCodePath, "")
            end
        end,

        -- label
        getLabel = function()
            local data = fs.readFile(eepromLabelPath)
            if data then
                return data
            else
                return "EEPROM"
            end 
        end,
        setLabel = function(label)
            if label then
                checkArg(1, label, "string")
                label = unicode.sub(label, 1, maxLabelSize)
            else
                label = "EEPROM"
            end
            fs.writeFile(eepromLabelPath, label)
            return label
        end,
        
        -- control
        getChecksum = function()
            return "00000000"
        end,
        makeReadonly = function(checksum)
            if checksum ~= eeprom.getChecksum() then
                return nil, "incorrect checksum"
            end
            return true
        end
    }
    return eeprom
end

function vmx.create(eepromPath, diskSettings, address)
    local vm = {}
    vm.env = vmx.createBaseEnv()
    vm.address = address or uuid.next()
    vm.deviceinfo = {}
    for address, info in pairs(lastinfo.deviceinfo) do
        if not component.isConnected(address) then
            vm.deviceinfo[address] = info
        end
    end
    
    function vm.bindComponent(tbl, noEvent)
        vm.internalComponent.bind(tbl)
        vm.deviceinfo[tbl.address] = tbl.deviceinfo or {}
        if not noEvent then
            vm.internalComputer.pushSignal("component_added", tbl.address, tbl.type)
        end
    end

    function vm.unbindComponent(tbl, noEvent)
        vm.internalComponent.unbind(tbl)
        vm.deviceinfo[tbl.address] = nil
        if not noEvent then
            vm.internalComputer.pushSignal("component_removed", tbl.address, tbl.type)
        end
    end

    function vm.pushSignal(...)
        vm.internalComputer.pushSignal(...)
    end

    function vm.bindTmp(address)
        if vm.tmpAddress then return false end
        vm.tmpAddress = address or uuid.next()

        return true
    end

    function vm.bootstrap()
        local eeprom = vm.componentlib.list("eeprom")()
        if eeprom then
            local code = vm.componentlib.invoke(eeprom, "get")
            if code and #code > 0 then
                local bios, reason = load(code, "=bios", "t", vm.env)
                if bios then
                    vm.internalComputer.clearQueue()
                    vm.startTime = computer.uptime()
                    return bios, {n=0}
                end
                error("failed loading bios: " .. reason, 2)
            end
        end
        error("no bios found; install a configured EEPROM", 2)
    end

    function vm.loop(pullEvent)
        local result = {pcall(vm.bootstrap)}
        if result[1] then
            local co = coroutine.create(result[2])
            local args = result[3]
            while true do
                local result = {coroutine.resume(co, table.unpack(args, 1, args.n))}
                args = nil
                if not result[1] then
                    return table.unpack(result)
                else
                    local returnType = type(result[2])
                    if returnType == "boolean" then
                        if result[2] then
                            return true, "reboot"
                        else
                            return true
                        end
                    elseif returnType == "number" then
                        args = table.pack(pullEvent(vm, result[2]))
                    else
                        args = table.pack(pullEvent(vm))
                    end
                end
            end
        else
            return nil, tostring(result[2])
        end
    end

    ---- base init
    local componentlib, internalComponent = vmx.createComponentLib()
    vm.env.component = componentlib
    vm.componentlib = componentlib
    vm.internalComponent = internalComponent

    local computerlib, internalComputer = vmx.createComputerLib(vm)
    vm.env.computer = computerlib
    vm.computerlib = computerlib
    vm.internalComputer = internalComputer

    local componentComputer = vmx.createVirtualComputer(vm)
    vm.bindComponent(componentComputer)
    
    ---- bind components
    if eepromPath then
        vm.eeprom = vmx.createVirtualEeprom(eepromPath)
        vm.bindComponent(vm.eeprom)
    end

    if diskSettings then
        vm.bindComponent(vmx.fromVirtual(fs.dump(table.unpack(diskSettings))))
    end

    return vm
end

function vmx.hookGraphic(screen)
    local gpuAddress = graphic.findGpuAddress(screen)
    local scrsvTurnOn
    if gpuAddress then
        scrsvTurnOn = screensaver.noScreensaver(screen)
        palette.setDefaultPalette(screen, true)
        pcall(component.invoke, gpuAddress, "setActiveBuffer", 0)
        pcall(component.invoke, gpuAddress, "freeAllBuffers")
        graphic.gpuPrivateList[gpuAddress] = true
    end
    
    return function ()
        graphic.gpuPrivateList[gpuAddress] = nil
        pcall(component.invoke, gpuAddress, "setActiveBuffer", 0)
        pcall(component.invoke, gpuAddress, "freeAllBuffers")
        sysinit.initScreen(screen)
        scrsvTurnOn()
    end, gpuAddress
end

local function inVmComponentExists(vm, address)
    return not not vm.internalComponent.components[address]
end

function vmx.pullEvent(vm, timeout)
    local eventData = {event.pull(timeout)}
    if #eventData > 0 and (eventData[1] == "tablet_use" or inVmComponentExists(vm, eventData[2])) then
        return table.unpack(eventData)
    end
end

function vmx.fromReal(address)
    local tbl = {}
    tbl.address = address
    tbl.type = component.type(address)
    tbl.direct = {}
    tbl.docs = {}
    tbl.slot = component.slot(address)
    tbl.deviceinfo = lastinfo.deviceinfo[address]

    for name, direct in pairs(component.methods(address)) do
        tbl.direct[name] = direct
    end

    for key, value in pairs(component.proxy(address)) do
        tbl[key] = value
        tbl.docs[key] = tostring(value)
    end

    return tbl
end

function vmx.fromVirtual(fakeProxy)
    local tbl = {}
    tbl.docs = {}
    for key, value in pairs(fakeProxy) do
        tbl[key] = value
        tbl.docs[key] = tostring(value)
    end
    tbl.address = fakeProxy.address or uuid.next()
    tbl.type = fakeProxy.type
    tbl.slot = fakeProxy.slot or -1
    tbl.virtual = nil
    return tbl
end

vmx.unloadable = true
return vmx