local fs = require("filesystem")
local paths = require("paths")
local graphic = require("graphic")
local component = require("component")
local computer = require("computer")
local unicode = require("unicode")
local palette = require("palette")
local term = require("term")
local event = require("event")

local openbox = {}
openbox.nativeLibsList = {
    "computer",
    "component",
    "unicode",
    "colors",
    "sides",
    "sha256",
    "serialization",
    "uuid",
    "note"
}

function openbox:fpath(path)
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
        time = os.time,
        sleep = os.sleep
    }

    function env.require(name)
        if self.libs[name] then
            return self.libs[name]
        end

        local libpath = self:fpath(name)
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

        return self:fpath("/tmp/" .. str)
    end

    function os.remove(path)
        return fs.remove(self:fpath(path))
    end

    function os.rename(path1, path2)
        return fs.rename(self:fpath(path1), self:fpath(path2))
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
        return loadfile(self:fpath(path), mode, lenv or env)
    end

    function env.dofile(path)
        return dofile(self:fpath(path))
    end


    function env.print(...)
        self.term:print(...)
    end

    return env
end

function openbox:execute(chunk, ...)
    local code, err = load(chunk, nil, nil, self.env)
    if not code then
        return nil, err
    end

    local result = {xpcall(code, debug.traceback, ...)}

    for id in pairs(self.timers) do
        event.cancel(id)
    end

    return table.unpack(result)
end

function openbox:clear()
    if self.screen then
        local gpu = graphic.findGpu(self.screen)
        palette.set(self.screen, self.oldPalette)
        gpu.setResolution(self.oldRX, self.oldRY)
        gpu.setBackground(0)
        gpu.setForeground(0xffffff)
        gpu.fill(1, 1, self.oldRX, self.oldRY, " ")
    end
end

function openbox.create(screen)
    local box = setmetatable({}, {__index = openbox})
    box.env = box:createEnv()
    box.path = "/data/openbox"
    box.libs = {}
    box.screen = screen
    box.oldPalette = palette.save(screen)
    box.timers = {}

    if screen then
        local gpu = graphic.findGpu(screen)
        box.oldRX, box.oldRY = gpu.getResolution()
        box.term = term.create(screen, 1, 1, box.oldRX, box.oldRY, true)
    end

    -- term
    box.libs.term = {}
    function box.libs.term.screen()
        return screen
    end

    function box.libs.term.gpu()
        if screen then
            return graphic.findGpu(screen)
        end
    end

    function box.libs.term.keyboard()
        if screen then
            return component.invoke(screen, "getKeyboards")[1]
        end
    end

    function box.libs.term.clear()
        local gpu = graphic.findGpu(screen)
        local rx, ry = gpu.getResolution()
        gpu.fill(1, 1, rx, ry, " ")
    end

    function box.libs.term.read()
        return box.term:read()
    end

    function box.libs.term.write(str)
        box.term:write(str)
    end

    -- tty
    box.libs.tty = box.libs.term

    -- io
    box.libs.io = {}
    function box.libs.io.read()
        return box.term:read()
    end

    function box.libs.io.write(str)
        return box.term:write(str)
    end

    -- event
    box.libs.event = {}
    box.libs.event.pull = event.pull
    box.libs.event.push = event.push

    function box.libs.timer(...)
        local id = event.timer(...)
        box.timers[id] = true
        return id
    end

    function box.libs.listen(...)
        local id = event.listen(...)
        box.timers[id] = true
        return id
    end

    function box.libs.cancel(id)
        event.cancel(id)
        box.timers[id] = nil
    end

    --end
    box.env.io = box.libs.io
    return box
end

openbox.unloadable = true
return openbox