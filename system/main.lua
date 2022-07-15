local gui_container = require("gui_container")
local component = require("component")
local graphic = require("graphic")
local programs = require("programs")
local calls = require("calls")
local event = require("event")

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

if #screens > 0 then
    local thread = require("thread") --подгружаю thread опционально, для экономии энергии

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