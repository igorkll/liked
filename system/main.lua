_G._OSVERSION = "liked: " .. tostring(getOSversion())

require("gui_container")
local component = require("component")
local graphic = require("graphic")
local programs = require("programs")
local calls = require("calls")
local fs = require("filesystem")
local computer = require("computer")

table.insert(programs.paths, "/data/userdata")
table.insert(programs.paths, "/data/userdata/apps")

unittests("/vendor/unittests")
unittests("/data/unittests")

autorunsIn("/vendor/autoruns")
autorunsIn("/data/autoruns")

------------------------------------

local screens = {}
for address in component.list("screen") do
    local gpu = graphic.findGpu(address)
    if gpu.setActiveBuffer and gpu.getActiveBuffer() ~= 0 then gpu.setActiveBuffer(0) end
    if gpu and gpu.maxDepth() ~= 1 then
        table.insert(screens, address)
    end
end

local desktop = assert(programs.load("desktop")) --подгружаю один раз, таблица _ENV обшая, так что там нельзя юзать глобалки

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
    printText("no supported screens/GPUs found")
    while true do
        computer.pullSignal()
    end
end