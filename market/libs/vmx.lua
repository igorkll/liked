local component = require("component")
local computer = require("computer")
local unicode = require("unicode")
local natives = require("natives")
local fs = require("filesystem")
local text = require("text")
local vmx = {}

local function spcall(...)
    local result = table.pack(pcall(...))
    if not result[1] then
        error(tostring(result[2]), 3)
    else
        return table.unpack(result, 2, result.n)
    end
end

function vmx.createBaseEnv()
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
        xpcall = xpcall,
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

function vmx.createComputerLib()
    local computerlib, internalComputer
    internalComputer = {
        maxEventsCount = 256,
        events = {},
        pullSignal = function(time)
            checkArg(1, time, "number", "nil")
            local startTime = computer.uptime()
            while true do
                if #internalComputer.events > 0 then
                    return table.unpack(table.remove(internalComputer.events))
                elseif time and computer.uptime() - startTime > time then
                    break
                end
            end
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
            return spcall(computer.beep, ...)
        end,

    }
    return computerlib, internalComputer
end

function vmx.createComponentLib()
    local componentlib, internalComponent
    internalComponent = {
        components = {},
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

            if type(comp[method]) ~= "function" then
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
                if type(func) == "function" then
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
        end
    }
    return componentlib, internalComponent
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
        address = "09fa0bce-5c9d-4193-9102-752917eddbc5",

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

function vmx.create(eepromPath)
    local vm = {}
    vm.env = vmx.createBaseEnv()

    local componentlib, internalComponent = vmx.createComponentLib()
    vm.env.component = componentlib
    vm.internalComponent = internalComponent

    local computerlib, internalComputer = vmx.createComputerLib()
    vm.env.computer = computerlib
    vm.internalComputer = internalComputer

    if eepromPath then
        vm.eeprom = vmx.createVirtualEeprom(eepromPath)
        vm.internalComponent.bind(vm.eeprom)
    end

    function vm.bindComponent(tbl, noEvent)
        vm.internalComponent.bind(tbl)
        if not noEvent then
            vm.internalComputer.pushSignal("component_added", tbl.address, tbl.type)
        end
    end

    function vm.unbindComponent(tbl, noEvent)
        vm.internalComponent.unbind(tbl)
        if not noEvent then
            vm.internalComputer.pushSignal("component_removed", tbl.address, tbl.type)
        end
    end

    function vm.bootstrap()
        local eeprom = componentlib.list("eeprom")()
        if eeprom then
            local code = componentlib.invoke(eeprom, "get")
            if code and #code > 0 then
                local bios, reason = load(code, "=bios", "t", vm.env)
                if bios then
                    return coroutine.create(bios)
                end
                error("failed loading bios: " .. reason, 2)
            end
        end
        error("no bios found; install a configured EEPROM", 2)
    end

    function vm.loop()
        local result = {pcall(vm.bootstrap)}
        if result[1] then
            local result = {pcall(vmx.loop, result[2])}
            if not result[1] then
                return nil, tostring(result[2])
            end
        else
            return nil, tostring(result[2])
        end
    end

    return vm
end

function vmx.getComponent(address)
    local tbl = {}
    tbl.address = address
    tbl.type = component.type(address)
    tbl.direct = {}
    tbl.docs = {}

    for name, direct in pairs(component.methods(address)) do
        tbl.direct[name] = direct
    end

    for key, value in pairs(component.proxy(address)) do
        tbl[key] = value
        tbl.docs[key] = tostring(value)
    end

    return tbl
end

function vmx.loop(co)
    while true do
        local result = {coroutine.resume(co)}
        
        if not result[1] then
            error(tostring(result[2]), 2)
        elseif coroutine.status(co) == "dead" then
            error("computer halted", 2)
        end
    end
end

vmx.unloadable = true
return vmx