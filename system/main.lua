--liked
_G._OSVERSION = "liked-v" .. tostring(getOSversion())

local gui_container = require("gui_container")
local programs = require("programs")
local fs = require("filesystem")
local registry = require("registry")
local event = require("event")

table.insert(programs.paths, "/data/userdata")
table.insert(programs.paths, "/data/userdata/apps")

unittests("/vendor/unittests")
unittests("/data/unittests")

autorunsIn("/vendor/autoruns")
autorunsIn("/data/autoruns")

------------------------------------

local screens = {}
local maxDepth = 0
for address in require("component").list("screen") do
    local graphic = require("graphic")
    local gpu = graphic.findGpu(address)
    if gpu then
        if gpu.setActiveBuffer and gpu.getActiveBuffer() ~= 0 then gpu.setActiveBuffer(0) end
        local depth = gpu.maxDepth()
        if gpu and depth > 1 then
            table.insert(screens, address)
            maxDepth = math.max(maxDepth, depth)
        end
    end
end

local desktop = assert(programs.load("desktop")) --подгружаю один раз для экономии ОЗУ, таблица _ENV обшая, так что там нельзя юзать глобалки

------------------------------------

if not fs.exists("/data/theme.plt") then
    pcall(fs.copy, "/system/themes/classic.plt", "/data/theme.plt")
end

if not fs.exists(gui_container.screenSaverPath) and not registry.screenSaverDefaultSetted then
    pcall(fs.copy, "/system/screenSavers/black screen.scrsv", gui_container.screenSaverPath)
    registry.screenSaverDefaultSetted = true
end

if not registry.shadowType and maxDepth ~= 0 then
    registry.shadowMode = "full"
    if maxDepth == 4 then
        registry.shadowType = "smart"
    else
        registry.shadowType = "advanced"
    end
end

------------------------------------

if #screens > 0 then
    local gui = require("gui") --нужно подключить заранию чтобы функции записались в calls.loaded
    local thread = require("thread") --подгружаю thread опционально, для экономии энергии и ОЗУ

    local recreate = {}
    local threads = {}
    for index, address in ipairs(screens) do
        recreate[index] = function ()
            gui_initScreen(address)
            
            local t = thread.create(desktop, address, index == 1)
            t.parentData.screen = address --для того чтобы можно было убивать дальнейшие патокаи через адрес экрана(информация от экране передаеться от патока к потоку ядром)
            t:resume() --поток по умалчанию спит

            threads[index] = t
        end
        recreate[index]()
    end

    event.wait()

    --[[
    while true do
        for i, v in ipairs(threads) do
            if v:status() == "dead" then
                event.errLog("crash in monitor \"" .. v.screen:sub(1, 4) .. "\" \"" .. (v.out[2] or "unknown error") .. "\" \"" .. (v.out[3] or "no traceback") .. "\"", 0)
                recreate[i]()
            end
        end
        event.sleep(1)
    end
    ]]
--elseif #screens == 1 then
--    local screen = screens[1]
--    gui_initScreen(screen)
--    desktop(screen, true)
else
    bootSplash("no supported screens/GPUs found")
    event.wait()
end