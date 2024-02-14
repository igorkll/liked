local component = require("component")
local computer = require("computer")
local unicode = require("unicode")
local natives = require("natives")
local vmx = {}

function vmx.createEnv(extensions)
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
        },

        computer = {

        }
    }

    if _VERSION == "Lua 5.3" or _VERSION == "Lua 5.4" then
        sandbox.bit32 = nil
        sandbox.utf8 = table.deepclone(utf8)
    end

    sandbox._G = sandbox
    if extensions then
        for k, v in pairs(extensions) do
            sandbox[k] = v
        end
    end
    return sandbox
end

vmx.unloadable = true
return vmx