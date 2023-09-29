--liked
_G._OSVERSION = "liked-v" .. tostring(getOSversion())
local bootloader = require("bootloader")
bootloader.runlevel = "user"

local fs = require("filesystem")
local graphic = require("graphic")
local programs = require("programs")
local component = require("component")

table.insert(programs.paths, "/data/userdata")
table.insert(programs.paths, "/data/userdata/apps")

------------------------------------

local screens = {}
local minDepth = math.huge
local maxDepth = 0
for address in component.list("screen") do
    local gpu = graphic.findGpu(address)
    if gpu then
        if gpu.setActiveBuffer and gpu.getActiveBuffer() ~= 0 then gpu.setActiveBuffer(0) end
        local depth = gpu.maxDepth()
        if gpu then
            table.insert(screens, address)
            maxDepth = math.max(maxDepth, depth)
            minDepth = math.min(minDepth, depth)
        end
    end
end
minDepth = math.round(minDepth)
maxDepth = math.round(maxDepth)

------------------------------------

function _G.initPal()
    if fs.exists("/data/theme.plt") then
        system_applyTheme("/data/theme.plt")
    else
        if minDepth == 1 then
            system_setTheme("/system/themes/original.plt")
        else
            system_setTheme("/system/themes/classic.plt")
        end
    end
end
local gui_container = require("gui_container")
_G.initPal = nil

local gui = require("gui") --нужно подключить заранию чтобы функции записались в calls.loaded
local liked = require("liked")
local registry = require("registry")
local event = require("event")
local computer = require("computer")
local system = require("system")
local desktop = assert(programs.load("desktop")) --подгружаю один раз для экономии ОЗУ, таблица _ENV обшая, так что там нельзя юзать глобалки

------------------------------------

if not registry.wallpaperBaseColor then
    if minDepth == 1 then
        registry.wallpaperBaseColor = "black"
    else
        registry.wallpaperBaseColor = "lightBlue"
    end
end

if not registry.timeZone then
    registry.timeZone = 0
end

if not registry.powerMode then
    local devicetype = system.getDeviceType()
    if devicetype == "tablet" then
        registry.powerMode = "energy saving"
    else
        registry.powerMode = "power"
    end
end
liked.applyPowerMode()

if not registry.branch then
    registry.branch = "main"
end

if not registry.bufferType then
    if computer.totalMemory() >= (gui_container.minRamForDBuff * 1024) then
        registry.bufferType = "software"
    else
        registry.bufferType = "none"
    end
end
liked.applyBufferType()

if not fs.exists(gui_container.screenSaverPath) and not registry.screenSaverDefaultSetted then
    pcall(fs.copy, "/system/screenSavers/black_screen.scrsv", gui_container.screenSaverPath)
    registry.screenSaverDefaultSetted = true
end

if not registry.shadowType then
    registry.shadowMode = "full"
    if minDepth == 4 then
        registry.shadowType = "smart"
    elseif minDepth == 8 then
        registry.shadowType = "advanced"
    else
        registry.shadowType = "none"
    end
end

------------------------------------

bootloader.unittests("/vendor/unittests")
bootloader.unittests("/data/unittests")

bootloader.autorunsIn("/vendor/autoruns")
bootloader.autorunsIn("/data/autoruns")

------------------------------------

if #screens > 0 then
    local thread = require("thread")

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
    bootloader.bootSplash("no supported screens/GPUs found")
    event.wait()
end