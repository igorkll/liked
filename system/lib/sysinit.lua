local sysinit = {}
sysinit.screenThreads = {}

function sysinit.applyPalette(path, screen)
    local fs = require("filesystem")
    local serialization = require("serialization")
    local component  = require("component")
    local graphic = require("graphic")
    local gui_container = require("gui_container")

    local colors = assert(serialization.load(path))

    local function movetable(maintable, newtable)
        for k, v in pairs(maintable) do
            maintable[k] = nil
        end
        for k, v in pairs(newtable) do
            maintable[k] = v
        end
    end

    local t3default = colors.t3default
    colors.t3default = nil

    movetable(gui_container.indexsColors, colors)
    movetable(gui_container.colors, {
        white     = colors[1],
        orange    = colors[2],
        magenta   = colors[3],
        lightBlue = colors[4],
        yellow    = colors[5],
        lime      = colors[6],
        pink      = colors[7],
        gray      = colors[8],
        lightGray = colors[9],
        cyan      = colors[10],
        purple    = colors[11],
        blue      = colors[12],
        brown     = colors[13],
        green     = colors[14],
        red       = colors[15],
        black     = colors[16]
    })

    if screen ~= true then
        local blackWhile
        local function applyOnScreen(address)
            if graphic.maxDepth(address) ~= 1 then
                if t3default and graphic.getDepth(address) == 8 then
                    graphic.fakePalette = colors
                    if not blackWhile then
                        blackWhile = assert(serialization.load("/system/t3default.plt"))
                    end
                    graphic.setPalette(address, blackWhile)
                else
                    graphic.fakePalette = nil
                    graphic.setPalette(address, colors)
                end
            end
        end

        if screen then
            applyOnScreen(screen)
        else
            for address in component.list("screen") do
                applyOnScreen(address)
            end
        end
    end
end

function sysinit.getResolution(screen)
    local graphic = require("graphic")
    local mx, my = graphic.maxResolution(screen)
    if mx > 80 or my > 25 then
        mx = 80
        my = 25
    end
    return mx, my
end

function sysinit.initScreen(screen)
    local graphic = require("graphic")
    local component = require("component")

    pcall(component.invoke, screen, "turnOn")

    local mx, my = sysinit.getResolution(screen)

    graphic.setDepth(screen, graphic.maxDepth(screen))
    graphic.setResolution(screen, mx, my)
    graphic.clear(0)
    graphic.forceUpdate(screen)
    sysinit.applyPalette(sysinit.initPalPath, screen)
end

function sysinit.runShell(screen, customShell)
    local thread = require("thread")
    local registry = require("registry")
    local liked = require("liked")

    sysinit.initScreen(screen)
    
    local shellName = "shell"
    if customShell then
        shellName = customShell
    elseif registry.data.shell and registry.data.shell[screen] then
        shellName = registry.data.shell[screen]
    end

    if sysinit.screenThreads[screen] then sysinit.screenThreads[screen]:kill() end
    local t = thread.create(assert(liked.loadApp(shellName, screen)))
    t.parentData.screen = screen
    t:resume() --поток по умалчанию спит
    sysinit.screenThreads[screen] = t
end

function sysinit.init(box)
    local fs = require("filesystem")
    _G._OSVERSION = "liked-v" .. assert(fs.readFile("/system/version.cfg"))
    local bootloader = require("bootloader")
    bootloader.runlevel = "user"

    local graphic = require("graphic")
    local programs = require("programs")
    local component = require("component")
    local package = require("package")

    table.insert(package.paths, "/system/likedlib")
    table.insert(programs.paths, "/data/apps")
    table.insert(programs.paths, "/system/apps")
    table.insert(programs.paths, "/vendor/apps")

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
        sysinit.initPalPath = "/system/palette.plt"
        sysinit.applyPalette(sysinit.initPalPath, true)
    else
        sysinit.initPalPath = "/data/palette.plt"

        if fs.exists(sysinit.initPalPath) then
            sysinit.applyPalette(sysinit.initPalPath, true)
        else
            local palette = require("palette")
            if minDepth == 1 then
                palette.setSystemPalette("/system/palettes/original.plt", true)
            else
                palette.setSystemPalette("/system/palettes/classic.plt", true)
            end
        end
    end

    local gui_container = require("gui_container")
    local gui = require("gui") --нужно подключить заранию чтобы функции записались в calls.loaded

    package.hardAutoUnloading = true
    if package.isInstalled("sysmode") then
        require("sysmode").init()
    end

    local thread = require("thread")
    local liked = require("liked")
    local registry = require("registry")
    local event = require("event")
    local system = require("system")
    
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

    ------------------------------------

    bootloader.unittests("/vendor/unittests")
    bootloader.unittests("/data/unittests")

    bootloader.autorunsIn("/vendor/autoruns")
    bootloader.autorunsIn("/data/autoruns")

    require("autorun").autorun()
    
    if programs.find("preinit") then
        local ok, err = liked.execute("preinit")
        if not ok then
            event.errLog(err)
        end
    end

    ------------------------------------

    for index, address in ipairs(screens) do
        sysinit.runShell(address)
    end

    event.hyperListen(function (eventType, cuuid, ctype)
        if ctype == "screen" then
            if eventType == "component_added" then
                if not sysinit.screenThreads[cuuid] and graphic.findGpuAddress(cuuid) then
                    sysinit.runShell(cuuid)
                end
            elseif eventType == "component_removed" then
                if sysinit.screenThreads[cuuid] then
                    sysinit.screenThreads[cuuid]:kill()
                    sysinit.screenThreads[cuuid] = nil
                end
            end
        end
    end)

    thread.create(function ()
        while true do
            for screen, th in pairs(sysinit.screenThreads) do
                if th:status() == "dead" then
                    th:kill()
                    sysinit.runShell(screen)
                end
            end
            os.sleep(1)    
        end
    end):resume()

    sysinit.init = nil
    sysinit.inited = true
end

return sysinit