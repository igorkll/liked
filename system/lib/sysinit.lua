local sysinit = {}

function sysinit.init(box)
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
    local hardwareBufferAvailable = false
    for address in component.list("screen") do
        local gpu = graphic.findGpu(address)
        if gpu then
            if gpu.setActiveBuffer then
                hardwareBufferAvailable = true
                if gpu.getActiveBuffer() ~= 0 then
                    gpu.setActiveBuffer(0)
                end
            end
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

    if box then
        _G.initPalPath = "/system/palette.plt"
        function _G.initPal()
            system_applyTheme(_G.initPalPath)
        end
    else
        _G.initPalPath = "/data/theme.plt"
        function _G.initPal()
            if fs.exists(_G.initPalPath) then
                system_applyTheme(_G.initPalPath)
            else
                if minDepth == 1 then
                    system_setTheme("/system/themes/original.plt")
                else
                    system_setTheme("/system/themes/classic.plt")
                end
            end
        end
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
    local desktop = assert(programs.load("desktop")) --подгружаю один раз для экономии ОЗУ, таблица _ENV обшая, так что там нельзя юзать глобалки

    ------------------------------------

    if not box then
        if not registry.timeZone then
            registry.timeZone = 0
        end

        if not registry.branch then
            registry.branch = "main"
        end
    end

    ------------------------------------

    if not registry.wallpaperBaseColor then
        if minDepth == 1 then
            registry.wallpaperBaseColor = "black"
        else
            registry.wallpaperBaseColor = "lightBlue"
        end
    end

    ------------------------------------

    if not registry.powerMode then
        local devicetype = system.getDeviceType()
        if devicetype == "tablet" then
            registry.powerMode = "energy saving"
        else
            registry.powerMode = "power"
        end
    end
    liked.applyPowerMode()

    ------------------------------------

    if not registry.bufferType then
        if hardwareBufferAvailable then
            registry.bufferType = "hardware"
        else
            registry.bufferType = "none"
        end
    end
    liked.applyBufferType()

    ------------------------------------

    if not fs.exists(gui_container.screenSaverPath) and not registry.screenSaverDefaultSetted then
        pcall(fs.copy, "/system/screenSavers/black_screen.scrsv", gui_container.screenSaverPath)
        registry.screenSaverDefaultSetted = true
    end

    ------------------------------------

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

    gui_container.refresh()

    bootloader.unittests("/vendor/unittests")
    bootloader.unittests("/data/unittests")
    bootloader.autorunsIn("/vendor/autoruns")
    bootloader.autorunsIn("/data/autoruns")

    ------------------------------------

    local screenThreads = {}

    local first = true
    local function runDesktop(screen)
        gui_initScreen(screen)
            
        local t = thread.create(desktop, screen, first)
        t.parentData.screen = screen --для того чтобы можно было убивать дальнейшие патокаи через адрес экрана(информация от экране передаеться от патока к потоку ядром)
        t:resume() --поток по умалчанию спит

        first = false
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

    sysinit.init = nil
end

return sysinit