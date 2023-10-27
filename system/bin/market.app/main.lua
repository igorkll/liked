local graphic = require("graphic")
local fs = require("filesystem")
local calls = require("calls")
local gui_container = require("gui_container")
local registry = require("registry")
local computer = require("computer")
local paths = require("paths")
local unicode = require("unicode")
local programs = require("programs")
local internet = require("internet")
local liked = require("liked")
local gui = require("gui")

local cacheReg = registry.new("/data/cache/market/versions.dat")
if not registry.libVersions then
    registry.libVersions = {}
end

local colors = gui_container.colors

------------------------------------

local title = "Market"

local screen, nickname, _, forceMode = ...
local rx, ry
do
    local gpu = graphic.findGpu(screen)
    rx, ry = gpu.getResolution()
end

local rootfs = fs.get("/")
local maxDepth = graphic.findGpu(screen).maxDepth()

local barTh, barRedraw = liked.drawUpBarTask(screen, true, colors.gray)

local function exec(...)
    barTh:suspend()
    local result = {programs.execute(...)}
    barTh:resume()
    return table.unpack(result)
end

------------------------------------

local netver = liked.lastVersion()

if not netver then
    gui.warn(screen, nil, nil, "connection error")
    return
end

if netver > liked.version() then
    gui.warn(screen, nil, nil, "please update the system, until the system is updated, the market will not work")
    return
end

------------------------------------

local gui_drawimage = calls.load("gui_drawimage")

local statusWindow = graphic.createWindow(screen, 1, 1, rx, 1)
local window = graphic.createWindow(screen, 1, 2, rx, ry - 1)

------------------------------------

local freeSpace

local function reFreeSpace()
    freeSpace = (rootfs.spaceTotal() - rootfs.spaceUsed()) / 1024
end

reFreeSpace()

------------------------------------

local urls = {}
local list = {}
local glibs = {}

local function modifyList(lst)
    if lst.libs then
        for name, info in pairs(lst.libs) do
            glibs[name] = info
        end
    end

    local function download(url)
        return assert(internet.getInternetFile(url))
    end
    
    local function save(path, data)
        assert(fs.writeFile(path, data))
    end

    for i, v in ipairs(lst) do
        local versionpath = paths.concat(v.path, "version.dat")
    
        if not v.getVersion then
            function v.getVersion(self)
                if fs.exists(versionpath) then
                    return fs.readFile(versionpath)
                else
                    return "unknown"
                end
            end
        end
    
        if not v.uninstall then
            function v.uninstall(self)
                liked.uninstall(screen, nickname, self.path)
            end
        end
    
        if not v.isInstalled then
            function v.isInstalled(self)
                return fs.exists(self.path)
            end
        end
    
        local _install = v.install or function (self)
            fs.makeDirectory(self.path)
            for _, name in ipairs(self.files or {"icon.t2p", "main.lua"}) do
                save(paths.concat(self.path, name), download(self.urlPrimaryPart .. name))
            end
        end
        function v.install(self)
            if v.libs then
                for _, name in ipairs(v.libs) do
                    local info = glibs[name]
                    local path = paths.concat("/data/lib", name .. ".lua")
                    if not fs.exists(path) or registry.libVersions[name] ~= info.version then
                        save(path, download(info.url))
                        registry.libVersions[name] = info.version
                    end
                end
            end

            save(versionpath, self.version)
            _install(self)
            if v.postInstall then
                v:postInstall()
            end

            local regPath = paths.concat(self.path, "reg.reg")
            if fs.exists(regPath) and not fs.isDirectory(regPath) then
                liked.assert(screen, programs.execute("applyReg", screen, nickname, regPath, true))
            end
            registry.save()
        end
    
        if not v.icon and v.urlPrimaryPart then
            v.icon = v.urlPrimaryPart .. "icon.t2p"
        end
    end
end

local function doList(path)
    if fs.exists(path) then
        local result = {pcall(getFile, path)}
        if result[1] then
            local result = {pcall(split2, unicode, result[2], {"\n"})}
            if result[1] then
                if type(result[2]) == "table" then
                    for _, url in ipairs(result[2]) do
                        if url ~= "" then
                            table.insert(urls, url)
                        end
                    end
                else
                    gui.warn(screen, nil, nil, "list-type-err: " .. (type(result[2]) or "unknown"))
                end
            else
                gui.warn(screen, nil, nil, "fail to parse list: " .. (result[2] or "unknown"))
            end
        else
            gui.warn(screen, nil, nil, "fail to read list: " .. (result[2] or "unknown"))
        end
    end
end

local customPath = "/data/market_urls.txt"

local function reList()
    urls = {}
    if not registry.disableSystemMarketUrls then
        doList("/system/market_urls_" .. registry.branch .. ".txt")
    end
    doList("/vendor/market_urls.txt")
    if not registry.disableCustomMarketUrls then
        doList(customPath)
    end

    list = {}
    for index, url in ipairs(urls) do
        local id = tostring(index) .. "."
    
        local data, err = getInternetFile(url)
        if data then
            local code, err = load(data, "=list" .. index, "t", _ENV)
            if code then
                local result = {pcall(code, screen, nickname, url)}
                if result[1] then
                    if type(result[2]) == "table" then
                        modifyList(result[2])
                        for _, app in ipairs(result[2]) do
                            table.insert(list, app)
                        end
                    else
                        gui.warn(screen, nil, nil, id .. "list-type-err: " .. (type(result[2]) or "unknown"))
                    end
                else
                    gui.warn(screen, nil, nil, id .. "list-err: " .. (result[2] or "unknown"))
                end
            else
                gui.warn(screen, nil, nil, id .. "list-err: " .. (err or "unknown"))
            end
        else
            gui.warn(screen, nil, nil, id .. "list-err: " .. (err or "unknown"))
        end
    end
end
reList()

------------------------------------

local instCache = {}
local verCache = {}
local downloaded = {}
local function applicationLabel(data, x, y)
    local applabel = graphic.createWindow(screen, x, y, rx - 2, 6)

    local supportErr
    if not forceMode then
        if data.minDiskSpace then
            if freeSpace < data.minDiskSpace then
                supportErr = "not enough space to install. need: " .. tostring(data.minDiskSpace) .. "KB"
            end
        end
        if data.minColorDepth and maxDepth < data.minColorDepth then
            local level = -1
            if data.minColorDepth == 1 then
                level = 1
            elseif data.minColorDepth == 4 then
                level = 2
            elseif data.minColorDepth == 8 then
                level = 3
            end
            supportErr = "the graphics system level is too low. need: " .. tostring(level)
        end
        if data.minRam and computer.totalMemory() < data.minRam * 1024 then
            supportErr = "too little RAM, on you " .. math.round(computer.totalMemory() / 1024) .. "KB need " .. math.round(data.minRam) .. "KB"
        end
    end

    local img

    local function draw(custImg)
        data.version = data.version or "unknown"

        applabel:clear(colors.black)
        applabel:fill(1, 1, 10, 6, colors.gray, colors.lightGray, "▒")
        applabel:set(12, 2, colors.black, colors.white, "name  : " .. (data.name or "unknown"))
        applabel:set(12, 3, colors.black, colors.white, "verion: " .. data.version)
        applabel:set(12, 4, colors.black, colors.white, "vendor: " .. (data.vendor or "unknown"))

        if data.license then
            applabel:set(applabel.sizeX - 13, 3, colors.blue, colors.white, "   license   ")
        end

        if custImg then
            applabel:set(applabel.sizeX - 13, 2, colors.purple, colors.white, "   loading   ")
        else
            local altCol = supportErr and colors.gray
            if instCache[data] and verCache[data] ~= data.version then
                applabel:set(applabel.sizeX - 13, 2, altCol or colors.orange, colors.white, "   update    ")
            elseif instCache[data] then
                applabel:set(applabel.sizeX - 13, 2, colors.red, colors.white,    "  uninstall  ")
            else
                applabel:set(applabel.sizeX - 13, 2, altCol or colors.green, colors.white,  "   install   ")
            end
        end
        
        gui_drawimage(screen, custImg or img, applabel:toRealPos(2, 2))
    end
    
    if data.icon then
        img = paths.concat("/data/cache/market", (data.name or "unknown") .. ".t2p")
        if not downloaded[img] then
            if not fs.exists(img) or cacheReg[data.name or "unknown"] ~= data.version then
                draw("/system/icons/app.t2p")
                fs.writeFile(img, getInternetFile(data.icon))
                cacheReg[data.name or "unknown"] = data.version
            end
            downloaded[img] = true
        end
    else
        img = "/system/icons/app.t2p"
    end

    if instCache[data] == nil then
        instCache[data] = not not data:isInstalled()
    end
    if data.getVersion and verCache[data] == nil then
        verCache[data] = data:getVersion()
    end

    draw()
    
    return {tick = function (eventData)
        local windowEventData = applabel:uploadEvent(eventData)
        if windowEventData[1] == "touch" then
            if windowEventData[3] >= (applabel.sizeX - 13) and windowEventData[3] < ((applabel.sizeX - 13) + 13) and windowEventData[4] == 3 and data.license then
                local license = "/tmp/market/" .. (data.name or "unknown") .. ".txt"

                gui_status(screen, nil, nil, "license loading...")
                assert(saveFile(license, assert(getInternetFile(data.license))))
                exec("edit", screen, nickname, license, true)
                fs.remove(license)

                return true
            elseif windowEventData[3] >= (applabel.sizeX - 13) and windowEventData[3] < ((applabel.sizeX - 13) + 13) and windowEventData[4] == 2 then
                local formattedName = " \"" .. (data.name or "unknown") .. "\"?"
                local formattedName2 = " \"" .. (data.name or "unknown") .. "\"..."
                if instCache[data] and verCache[data] ~= data.version then
                    if supportErr then
                        gui.warn(screen, nil, nil, supportErr)
                    elseif gui_yesno(screen, nil, nil, "update" .. formattedName) then
                        gui_status(screen, nil, nil, "updating" .. formattedName2)
                        data:uninstall()
                        data:install()
                    end
                elseif instCache[data] then
                    if gui_yesno(screen, nil, nil, "uninstall" .. formattedName) then
                        gui_status(screen, nil, nil, "uninstalling" .. formattedName2)
                        data:uninstall()
                    end
                else
                    if supportErr then
                        gui.warn(screen, nil, nil, supportErr)
                    elseif gui_yesno(screen, nil, nil, "install" .. formattedName) then
                        gui_status(screen, nil, nil, "installation" .. formattedName2)
                        data:install()
                    end
                end

                reFreeSpace()
                instCache[data] = data:isInstalled()
                verCache[data] = data:getVersion()
                draw()
                return true
            else
                return false
            end
        end
    end, draw = draw, offset = function (offset)
        y = y + offset
        applabel.y = applabel.y + offset
    end}
end

local function appInfo(data)
    local emptyDeskWindows = graphic.createWindow(screen, 2, 17, rx - 2, ry - 17)
    local deskWindows = graphic.createWindow(screen, 3, 18, rx - 4, ry - 19)

    local appLabel
    local function ldraw()
        statusWindow:clear(colors.gray)
        statusWindow:set(3, 1, colors.gray, colors.white, title)
        statusWindow:set(statusWindow.sizeX, statusWindow.sizeY, colors.red, colors.white, "X")
        statusWindow:set(1, statusWindow.sizeY, colors.red, colors.white, "<")
        barRedraw()

        window:clear(colors.white)

        appLabel = applicationLabel(data, 2, 3)
        
        emptyDeskWindows:clear(colors.black)
        deskWindows:clear(colors.black)
        deskWindows:setCursor(1, 1)
        deskWindows:write(data.description or "this application does not contain a description\nO_o", colors.black, colors.white, true)
    end
    ldraw()
    
    while true do
        local eventData = {computer.pullSignal()}
        if appLabel.tick(eventData) then
            ldraw()
        end

        local statusWindowEventData = statusWindow:uploadEvent(eventData)    
        if statusWindowEventData[1] == "touch" then
            if statusWindowEventData[3] == 1 and statusWindowEventData[4] == statusWindow.sizeY then
                break
            end
            if statusWindowEventData[3] == statusWindow.sizeX and statusWindowEventData[4] == statusWindow.sizeY then
                return true
            end
        end
    end
end

local listOffSet = 1
local appCount = 1
local appsTbl = {}
--[[
local function draw()
    window:clear(colors.white)

    statusWindow:clear(colors.gray)
    statusWindow:set((statusWindow.sizeX / 2) - (unicode.len(title) / 2), 1, colors.gray, colors.white, title)
    statusWindow:set(statusWindow.sizeX, statusWindow.sizeY, colors.red, colors.white, "X")

    appsTbl = {}
    appCount = 1
    for k, v in pairs(list) do
        if (not v.hided or gui_container.devModeStates[screen]) and appCount >= listOffSet and appCount <= window.sizeY then
            local installed = v:isInstalled()
            window:set(1, #appsTbl + 1, colors.white, installed and colors.green or colors.red, (v.name or k))
            --window:set(#(v.name or k) + 3, #appsTbl + 1, colors.white, installed and colors.green or colors.red, installed and "√" or "╳")
            table.insert(appsTbl, v)
        end
        appCount = appCount + 1
    end
end
]]

local appLabels = {}

local function drawStatus()
    statusWindow:clear(colors.gray)
    statusWindow:set(8, 1, colors.gray, colors.white, title)
    statusWindow:set(statusWindow.sizeX, statusWindow.sizeY, colors.red, colors.white, "X")
    if not registry.disableCustomMarketUrls then
        statusWindow:set(1, statusWindow.sizeY, colors.orange, colors.white, "CUSTOM")
    end
    barRedraw()
end

local function imitateLine(y)
    window:fill(2, y, window.sizeX - 2, 1, colors.black, 0, " ")
    window:fill(2, y, 10, 1, colors.gray, colors.lightGray, "▒")
end

local function draw(clear)
    if clear then
        window:clear(colors.white)
        drawStatus()
    end

    appLabels = {}
    appsTbl = {}
    appCount = 1
    
    local added = {}

    for i, v in ipairs(list) do
        if (not v.hided or gui_container.devModeStates[screen]) then
            local y = math.floor((4 + ((appCount - listOffSet) * 7)) + 0.5)
            if y > 1 and y < ry then
                table.insert(appLabels, applicationLabel(v, 2, y))
                table.insert(appsTbl, v)
            end

            if y < 1 then
                imitateLine(1)
            elseif y >= ry then
                imitateLine(window.sizeY)
            end

            added[y] = true
        end
        appCount = appCount + 1
    end

    if not clear then
        if not added[-3] then
            window:fill(2, 1, window.sizeX - 2, 1, colors.white, 0, " ")
        end

        if not added[window.sizeY + 1] then
            window:fill(2, window.sizeY, window.sizeX - 2, 1, colors.white, 0, " ")
        end
    end
end
draw(true)

------------------------------------

while true do
    local eventData = {computer.pullSignal()}
    local statusWindowEventData = statusWindow:uploadEvent(eventData)
    local windowEventData = window:uploadEvent(eventData)

    if statusWindowEventData[1] == "touch" then
        if statusWindowEventData[3] == statusWindow.sizeX and statusWindowEventData[4] == statusWindow.sizeY then
            break
        elseif statusWindowEventData[3] <= 6 and statusWindowEventData[4] == statusWindow.sizeY and not registry.disableCustomMarketUrls then
            exec("edit", screen, nickname, customPath)
            gui_status(screen, nil, nil, "list updating...")
            reList()
            instCache = {}
            verCache = {}
            downloaded = {}
            listOffSet = 1
            draw(true)
        end
    end

    if windowEventData[1] == "touch" then
        for index, value in ipairs(appLabels) do
            local ret = value.tick(eventData)
            if ret == false then
                gui_status(screen, nil, nil, "loading...")
                if appInfo(appsTbl[index]) then
                    break
                end
                draw(true)
            elseif ret then
                draw(true)
            end
        end
    elseif windowEventData[1] == "scroll" then
        if windowEventData[5] > 0 then
            --listOffSet = listOffSet - (1 / 7)
            listOffSet = listOffSet - 1
        else
            --listOffSet = listOffSet + (1 / 7)
            listOffSet = listOffSet + 1
        end

        if listOffSet > appCount - 3 then
            listOffSet = appCount - 3
        elseif listOffSet < 1 then
            listOffSet = 1
        else
            draw()
        end
    elseif windowEventData[1] == "key_down" then
        if windowEventData[4] == 208 then
            listOffSet = listOffSet + 1

            if listOffSet > appCount - 3 then
                listOffSet = appCount - 3
            elseif listOffSet < 1 then
                listOffSet = 1
            else
                draw()
            end
        elseif windowEventData[4] == 200 then
            listOffSet = listOffSet - 1

            if listOffSet > appCount - 3 then
                listOffSet = appCount - 3
            elseif listOffSet < 1 then
                listOffSet = 1
            else
                draw()
            end
        end
    end
end

fs.remove("/tmp/market")