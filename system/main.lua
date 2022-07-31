require("gui_container")
local component = require("component")
local graphic = require("graphic")
local programs = require("programs")
local calls = require("calls")

table.insert(programs.paths, "/data/userdata")
table.insert(programs.paths, "/data/userdata/apps")
--table.insert(programs.paths, "/data/bin")

do
    local fs = require("filesystem")
    local paths = require("paths")
    local event = require("event")
    local programs = require("programs")

    local function autorunsIn(path)
        for i, v in ipairs(fs.list(path)) do
            local full_path = paths.concat(path, v)
    
            local func, err = programs.load(full_path)
            if not func then
                event.errLog("err " .. (err or "unknown error") .. ", to load programm " .. full_path)
            else
                local ok, err = pcall(func)
                if not ok then
                    event.errLog("err " .. (err or "unknown error") .. ", in programm " .. full_path)
                end
            end        
        end
    end
    autorunsIn("/data/autoruns")
end

------------------------------------

local screens = {}
for address in component.list("screen") do
    local gpu = graphic.findGpu(address)
    if gpu.maxDepth() ~= 1 then
        table.insert(screens, address)
    end
end

local desktop = assert(programs.load("desktop"))--подгружаю один раз, таблица _ENV обшая, так что там нельзя юзать глобалки

------------------------------------

if #screens > 1 then
    local thread = require("thread") --подгружаю thread опционально, для экономии энергии
    local event = require("event")

    local threads = {}
    for _, address in ipairs(screens) do
        calls.call("gui_initScreen", address)
        local t = thread.create(desktop, address)
        t:resume() --поток по умалчанию спит
        t.screen = address
        table.insert(threads, t)
    end

    while true do
        for i, v in ipairs(threads) do
            if v:status() == "dead" then
                error("crash thread is monitor " .. v.screen:sub(1, 4) .. " " .. (v.out[2] or "unknown error") .. " " .. (v.out[3] or "not found"))
            end
        end
        event.sleep(1)
    end
elseif #screens == 1 then
    local screen = screens[1]
    calls.call("gui_initScreen", screen)
    assert(xpcall(desktop, debug.traceback, screen))
else
    error("no supported screen found", 0)
end