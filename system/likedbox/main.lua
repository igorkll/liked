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

_G.initPalPath = "/system/palette.plt"
function _G.initPal()
    system_applyTheme("/system/palette.plt")
end
local gui_container = require("gui_container")
_G.initPal = nil

local gui = require("gui") --нужно подключить заранию чтобы функции записались в calls.loaded
local thread = require("thread")
local liked = require("liked")
local registry = require("registry")
local event = require("event")
local computer = require("computer")
local system = require("system")

------------------------------------

if not registry.powerMode then
    registry.powerMode = "power"
end
liked.applyPowerMode()

if not registry.bufferType then
    registry.bufferType = "none"
end
liked.applyBufferType()

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

for str, tbl in pairs(registry.gui_container or {}) do
    for key, value in pairs(tbl) do
        gui_container[str][key] = value
    end
end

------------------------------------

bootloader.unittests("/vendor/unittests")
bootloader.unittests("/data/unittests")

bootloader.autorunsIn("/vendor/autoruns")
bootloader.autorunsIn("/data/autoruns")

------------------------------------

local screenThreads = {}
local function runDesktop(screen)
    gui_initScreen(screen)
    
    local t = thread.create(assert(programs.load("shell")), screen)
    t.parentData.screen = screen --для того чтобы можно было убивать дальнейшие патокаи через адрес экрана(информация от экране передаеться от патока к потоку ядром)
    t:resume() --поток по умалчанию спит

    screenThreads[screen] = t
end

for index, address in ipairs(screens) do
    runDesktop(address)
end

event.hyperListen(function (eventType, cuuid, ctype)
    if ctype == "screen" then
        if eventType == "component_added" then
            if not screenThreads[cuuid] then
                runDesktop(cuuid)
            end
        elseif eventType == "component_removed" then
            if screenThreads[cuuid] then
                screenThreads[cuuid]:kill()
                screenThreads[cuuid] = nil
            end
        end
    end
end)

while true do
    for screen, th in pairs(screenThreads) do
        if th:status() == "dead" then
            th:kill()
            runDesktop(screen)
        end
    end
    os.sleep(1)    
end