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
    local system = require("system")

    require("package").hardAutoUnloading = true
    
    ------------------------------------

    if not box and not registry.wallpaperBaseColor then
        if minDepth == 1 then
            registry.wallpaperBaseColor = "black"
        else
            registry.wallpaperBaseColor = "lightBlue"
        end
    end

    ------------------------------------

    if not registry.powerMode then
        local devicetype = system.getDeviceType()
        if devicetype == "tablet" and not box then
            registry.powerMode = "energy saving"
        else
            registry.powerMode = "power"
        end
    end
    liked.applyPowerMode()

    ------------------------------------

    if not registry.bufferType then
        if hardwareBufferAvailable and not box then
            registry.bufferType = "hardware"
        else
            registry.bufferType = "none"
        end
    end
    liked.applyBufferType()

    ------------------------------------

    if not box and not fs.exists(gui_container.screenSaverPath) and not registry.screenSaverDefaultSetted then
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

    liked.applyBeepState()

    gui_container.refresh()

    bootloader.unittests("/vendor/unittests")
    bootloader.unittests("/data/unittests")

    bootloader.autorunsIn("/vendor/autoruns")
    bootloader.autorunsIn("/data/autoruns")

    ------------------------------------

    local screenThreads = {}
    local runShell
    if box then
        function runShell(screen)
            gui_initScreen(screen)
    
            local t = thread.create(assert(programs.load("shell")), screen)
            t.parentData.screen = screen --для того чтобы можно было убивать дальнейшие патокаи через адрес экрана(информация от экране передаеться от патока к потоку ядром)
            t:resume() --поток по умалчанию спит

            screenThreads[screen] = t
        end
    else
        local desktop = assert(programs.load("desktop")) --подгружаю один раз для экономии ОЗУ, таблица _ENV обшая, так что там нельзя юзать глобалки
        local first = true

        function runShell(screen)
            gui_initScreen(screen)
                
            local t = thread.create(desktop, screen, first)
            t.parentData.screen = screen --для того чтобы можно было убивать дальнейшие патоки через адрес экрана(информация от экране передаеться от патока к потоку ядром)
            t:resume() --поток по умалчанию спит
    
            first = false
            screenThreads[screen] = t
        end
    end
    

    ------------------------------------

    for index, address in ipairs(screens) do
        runShell(address)
    end

    event.hyperListen(function (eventType, cuuid, ctype)
        if ctype == "screen" then
            if eventType == "component_added" then
                if not screenThreads[cuuid] then
                    runShell(cuuid)
                end
            elseif eventType == "component_removed" then
                if screenThreads[cuuid] then
                    screenThreads[cuuid]:kill()
                    screenThreads[cuuid] = nil
                end
            end
        end
    end)

    thread.create(function ()
        while true do
            for screen, th in pairs(screenThreads) do
                if th:status() == "dead" then
                    th:kill()
                    runShell(screen)
                end
            end
            os.sleep(1)    
        end
    end):resume()

    sysinit.init = nil
end

return sysinit