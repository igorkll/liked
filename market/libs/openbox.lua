local fs = require("filesystem")
local paths = require("paths")
local graphic = require("graphic")
local component = require("component")
local computer = require("computer")
local unicode = require("unicode")
local openbox = {}
openbox.nativeLibsList = {
    "computer",
    "unicode",
    "colors",
    "sides",
    "sha256",
    "serialization",
    "uuid",
    "note"
}

function openbox:path(path)
    return paths.sconcat(self.path, path) or self.path
end

function openbox:createEnv()
    local env = {}
    env._G = env

    env._VERSION = _VERSION
    env._OSVERSION = "OpenOS 1.8.3"

    env.setmetatable = setmetatable
    env.getmetatable = getmetatable
    env.assert = assert
    env.next = next
    env.select = select
    env.tonumber = tonumber
    env.tostring = tostring
    env.pairs = pairs
    env.ipairs = ipairs
    env.rawget = rawget
    env.rawset = rawset
    env.rawlen = rawlen
    env.rawequals = rawequal
    env.pcall = pcall
    env.xpcall = xpcall
    env.type = type
    env.error = error

    env.coroutine = table.deepclone(coroutine)
    env.table = table.deepclone(table)
    env.math = table.deepclone(math)
    env.string = table.deepclone(string)
    env.bit32 = table.deepclone(bit32)
    env.utf8 = table.deepclone(utf8)
    env.debug = table.deepclone(debug)

    env.os = {
        clock = os.clock,
        data = os.data,
        difftime = os.difftime,
        exit = os.exit,
        time = os.time
    }

    function os.require(name)
        if self.libs[name] then
            return self.libs[name]
        end

        local libpath = self:path(name)
        if fs.exists(libpath) then
            if fs.isDirectory(libpath) then
                local initfile = paths.concat(libpath, "init.lua")
                if fs.exists(initfile) and not fs.isDirectory(initfile) then
                    local lib = loadfile(initfile, nil, self.env)()
                    self.libs[name] = lib
                    return lib
                end
            else
                local lib = loadfile(libpath, nil, self.env)()
                self.libs[name] = lib
                return lib
            end
        end

        if table.exists(openbox.nativeLibsList, name) then
            return require(name)
        end

        error("failed to find lib \"" .. name .. "\"", 2)
    end

    function os.tmpname()
        local str = ""
        for i = 1, 9 do
            str = str .. tostring(math.round(math.random(0, 9)))
        end

        return self:path("/tmp/" .. str)
    end

    function os.remove(path)
        return fs.remove(self:path(path))
    end

    function os.rename(path1, path2)
        return fs.rename(self:path(path1), self:path(path2))
    end

    local trashEnv = {}
    function os.getenv(var)
        return trashEnv[var]
    end
    function os.setenv(var, new)
        trashEnv[var] = new
        return new
    end


    function env.load(chunk, chunkname, mode, lenv)
        return load(chunk, chunkname, mode, lenv or env)
    end

    function env.loadfile(path, mode, lenv)
        return loadfile(self:path(path), mode, lenv or env)
    end

    function env.dofile(path)
        return dofile(self:path(path))
    end

    return env
end

function openbox:execute(chunk, ...)
    local code, err = load(chunk, nil, nil, self.env)
    if not code then
        return nil, err
    end

    return pcall(code, ...)
end

function openbox.create(screen)
    local box = setmetatable({}, {__index = openbox})
    box.env = box:createEnv()
    box.path = "/data/openbox"
    box.libs = {}

    return box
end

openbox.unloadable = true
return openbox