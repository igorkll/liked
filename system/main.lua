--liked
_G._OSVERSION = "liked v" .. tostring(getOSversion())

require("gui_container")
local programs = require("programs")

table.insert(programs.paths, "/data/userdata")
table.insert(programs.paths, "/data/userdata/apps")

unittests("/vendor/unittests")
unittests("/data/unittests")

autorunsIn("/vendor/autoruns")
autorunsIn("/data/autoruns")

------------------------------------

local screens = {}
for address in require("component").list("screen") do
    local graphic = require("graphic")
    local gpu = graphic.findGpu(address)
    if gpu then
        if gpu.setActiveBuffer and gpu.getActiveBuffer() ~= 0 then gpu.setActiveBuffer(0) end
        if gpu and gpu.maxDepth() ~= 1 then
            table.insert(screens, address)
        end
    end
end

local desktop = assert(programs.load("desktop")) --подгружаю один раз для экономии ОЗУ, таблица _ENV обшая, так что там нельзя юзать глобалки

------------------------------------

if #screens > 1 then
    local thread = require("thread") --подгружаю thread опционально, для экономии энергии и ОЗУ
    local event = require("event")

    local recreate = {}
    local threads = {}
    for index, address in ipairs(screens) do
        recreate[index] = function ()
            gui_initScreen(address)
            
            local t = thread.create(desktop, address, index == 1)
            t.screen = address
            t:resume() --поток по умалчанию спит

            threads[index] = t
        end
        recreate[index]()
    end

    while true do
        for i, v in ipairs(threads) do
            if v:status() == "dead" then
                event.errLog("crash in monitor \"" .. v.screen:sub(1, 4) .. "\" \"" .. (v.out[2] or "unknown error") .. "\" \"" .. (v.out[3] or "no traceback") .. "\"", 0)
                recreate[i]()
            end
        end
        event.sleep(1)
    end
elseif #screens == 1 then
    local screen = screens[1]
    gui_initScreen(screen)
    desktop(screen, true)
else
    printText("no supported screens/GPUs found")
    while true do
        require("computer").pullSignal()
    end
end