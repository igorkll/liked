local component = require("component")
local computer = require("computer")
local unicode = require("unicode")
local natives = require("natives")
local fs = require("filesystem")
local vmx = {}

local function spcall(...)
    local result = table.pack(pcall(...))
    if not result[1] then
        error(tostring(result[2]), 0)
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
    local computer, internalComputer
    internalComputer = {
        events = {}
    }
    computer = {
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

        --base
        beep = function(...)
            return spcall(computer.beep, ...)
        end,

    }
    return computer, internalComputer
end

function vmx.createComponentLib()
    local component, internalComponent
    component = {

    }
    internalComponent = {
        bind = function(tbl)
            
        end
    }
    return component, internalComponent
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

    return vm
end

vmx.unloadable = true
return vmx