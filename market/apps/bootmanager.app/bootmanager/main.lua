local computer = computer
local component = component
local tmpfs = component.proxy(computer.tmpAddress())
local bootfs = component.proxy(computer.getBootAddress())

local function getGPU(screen)
    for address in component.list("gpu", true) do
        if component.invoke(address, "getScreen") == screen then
            return component.proxy(address)
        end
    end
    local gpu = component.proxy(component.list("gpu", true)() or "")
    if gpu then
        gpu.bind(screen, false)
        return gpu
    end
end

local function screens()
    local iter = component.list("screen", true)
    return function ()
        local screen = iter()
        if screen then
            return getGPU(screen), screen
        end
    end
end

local function invert(gpu)
    gpu.setBackground(gpu.setForeground(gpu.getBackground()))
end

local function centerPrint(gpu, y, text)
    local rx, ry = gpu.getResolution()
    gpu.set(((rx / 2) - (unicode.len(text) / 2)) + 1, y, text)
end

local function unserialize(str)
    local code = load("return " .. str, "=unserialize", "t", {math={huge=math.huge}})
    if code then
        local result = {pcall(code)}
        computer.pullSignal(0)
        if result[1] and type(result[2]) == "table" then
            return result[2]
        end
    end
end

local function readFile(fs, path)
    local file, err = fs.open(path, "rb")
    if not file then return nil, err end
    local buffer = ""
    repeat
        local data = fs.read(file, math.huge)
        buffer = buffer .. (data or "")
    until not data
    fs.close(file)
    return buffer
end

local function writeFile(fs, path, data)
    local file, err = fs.open(path, "wb")
    if not file then return nil, err end
    local ok, err = fs.write(file, data)
    if not ok then
        pcall(fs.close, file)
        return nil, err
    end
    fs.close(file)
    return true
end

local function serialize(tbl)
    local str = "{"
    for key, data in pairs(tbl) do
        str = str .. "[\"" .. key .. "\"]=\"" .. data .. "\","
    end
    return str:sub(1, #str - 1) .. "}"
end

local function bootTo(proxy, path, ...)
    local address = proxy.address
    computer.getBootAddress = function()
        return address
    end
    assert(load(assert(readFile(proxy, path)), "=init", nil, _G))(...)
    computer.shutdown()
end

local function mineOSboot(proxy)
    --mineOS получает адрес загрузочного диска из eeprom.getData
    --если у пользователя установлен eeprom в data которого находиться не только адрес загрузочного диска, все бы пошло по бараде
    --данный код делает так, чтобы mineOS получала фейковый eeprom-data в котором будет только адрес загрузочного диска
    --что обеспечит совместимость с всеми прошивками eeprom
    local invoke = component.invoke
    local eeprom = component.list("eeprom")()
    function component.invoke(address, method, ...)
        if address == eeprom then
            if method == "getData" then
                return proxy.address
            else
                error("access denied", 2) --у mineOS не будет доступа к eeprom, чтобы исключить воздействия вирусов(кой таких в mineOS пално)
            end
        end

        local result = {pcall(invoke, address, method, ...)}
        if not result[1] then
            error(result[2], 2) --для правильной обработки ошибок стоит error level 2
        else
            return table.unpack(result, 2)
        end
    end

    assert(load(assert(readFile(proxy, "/OS.lua")), "=init", nil, _G))()
    computer.shutdown()
end

local function readSysinfo(fs, path)
    if fs.exists(path) then
        local info = unserialize(assert(readFile(fs, path)))
        local params = {"name", "version"}
        local tbl = {}
        for i, v in ipairs(params) do
            if info[v] then
                tbl[v] = info[v]
            else
                local varpath = info[v .. "Path"]
                if varpath and fs.exists(varpath) then
                    tbl[v] = assert(readFile(fs, varpath))
                end
            end
        end
        return tbl
    end
end

local sysinfoFile = "/system/sysinfo.cfg"
local function likeOSname(proxy)
    local str = "likeOS based system"
    local info = readSysinfo(proxy, sysinfoFile)
    if info and info.name then
        str = str .. " (" .. tostring(info.name)
        if info.version then
            str = str .. " " .. tostring(info.version)
        end
        str = str .. ")"
    end
    return str
end

local function findSystems(address)
    local tbl = {}
    local proxy = component.proxy(address)

    local isPipes = proxy.exists("/boot/kernel/pipes")

    if proxy.exists("/system/core/bootloader.lua") then
        table.insert(tbl, {
            likeOSname(proxy),
            function ()
                bootTo(proxy, "/system/core/bootloader.lua")
            end,
            address
        })
    elseif not isPipes then
        if proxy.exists("/lib/core/full_event.lua") then --I hope this file will not be found in other operating systems to avoid conflicts.
            table.insert(tbl, {
                "openOS",
                function ()
                    bootTo(proxy, "/init.lua")
                end,
                address
            })
        elseif proxy.exists("/init.lua") then
            table.insert(tbl, {
                "unknown",
                function ()
                    bootTo(proxy, "/init.lua")
                end,
                address
            })
        end
    end

    if isPipes then
        table.insert(tbl, {
            "plan9k",
            function ()
                bootTo(proxy, "/boot/kernel/pipes")
            end,
            address
        })
    end

    if proxy.exists("/OS.lua") then
        table.insert(tbl, {
            "mineOS",
            function ()
                mineOSboot(proxy)
            end,
            address
        })
    end

    if proxy.exists("/openOS.lua") then
        table.insert(tbl, {
            "openOS",
            function ()
                bootTo(proxy, "/openOS.lua")
            end,
            address
        })
    end

    local function addBootOption(path)
        for _, name in ipairs(proxy.list(path) or {}) do
            if name ~= "pipes" then
                table.insert(tbl, {
                    name,
                    function ()
                        bootTo(proxy, path .. name)
                    end,
                    address
                })
            end
        end
    end
    addBootOption("/boot/kernel/")

    return tbl
end

local function menu(label, strs, funcs, autoTimeout)
    local selected = 1
    local startTime = computer.uptime()

    if not funcs[selected] then
        selected = selected + 1
        if not funcs[selected] then
            selected = nil
        end
    end

    local function getAutotime()
        local autotime = math.ceil(autoTimeout - (computer.uptime() - startTime))
        if autotime > autoTimeout then
            return autoTimeout
        elseif autotime < 0 then
            return 0
        end
        return autotime
    end

    local function redraw(otherTime)
        for gpu in screens() do
            local rx, ry = gpu.getResolution()
            gpu.fill(1, 1, rx, ry, " ")

            invert(gpu)

            gpu.fill(1, 1, rx, 1, " ")
            centerPrint(gpu, 1, label)

            gpu.fill(1, ry, rx, 1, " ")
            gpu.set(2, ry, "Enter=Choose    ↑-UP    ↓-DOWN")

            for i, v in ipairs(strs) do
                if i == selected then
                    gpu.fill(2, i + 2, rx - 2, 1, " ")
                    gpu.set(2, i + 2, v)
                    break
                end
            end

            invert(gpu)
            for i, v in ipairs(strs) do
                if i ~= selected then
                    gpu.set(2, i + 2, v)
                end
            end

            if autoTimeout then
                gpu.set(3, ry - 2, "autorun of the selected system after: " .. (otherTime or getAutotime()))
            end
        end
    end
    redraw()

    while true do
        local eventData = {computer.pullSignal(autoTimeout and 0.5)}
        local oldAutotimeExists = autoTimeout
        if eventData[1] == "key_down" then
            if eventData[4] == 28 then
                if autoTimeout then
                    autoTimeout = nil
                    redraw()
                end
                if selected and funcs[selected](strs[selected], eventData[5]) then
                    break
                end
            elseif eventData[4] == 200 then
                autoTimeout = nil
                if selected then
                    local oldSelect = selected
                    selected = selected - 1
                    if selected < 1 then
                        selected = 1
                        if oldAutotimeExists then
                            redraw()
                        end
                    else
                        if not funcs[selected] then
                            selected = selected - 1
                            if not funcs[selected] then
                                selected = oldSelect
                            end
                        end
                        redraw()
                    end
                elseif oldAutotimeExists then
                    redraw()
                end
            elseif eventData[4] == 208 then
                autoTimeout = nil
                if selected then
                    local oldSelect = selected
                    selected = selected + 1
                    if selected > #strs then
                        selected = #strs
                        if oldAutotimeExists then
                            redraw()
                        end
                    else
                        if not funcs[selected] then
                            selected = selected + 1
                            if not funcs[selected] then
                                selected = oldSelect
                            end
                        end
                        redraw()
                    end
                elseif oldAutotimeExists then
                    redraw()
                end
            end
        end

        if autoTimeout then
            if getAutotime() <= 0 then
                redraw(0)
                funcs[selected]()
            end
            redraw()
        end
    end
end

--------------------------------

for gpu, screen in screens() do
    component.invoke(screen, "turnOn")
    gpu.setDepth(1)
    gpu.setDepth(gpu.maxDepth())
    gpu.setBackground(0)
    gpu.setForeground(0xffffff)
    local mx, my = gpu.maxResolution()
    if mx > 80 or my > 25 then
        mx = 80
        my = 25
    end
    gpu.setResolution(mx, my)
    gpu.fill(1, 1, mx, my, " ")
end

local strs = {}
local funcs = {}

local function getTitle(address)
    return "disk \"" .. (component.invoke(address, "getLabel") or "no-label") .. "\" (" .. address:sub(1, 8) .. ")"
end

---- systems on self disk
table.insert(strs, "------ self " .. getTitle(bootfs.address))
table.insert(funcs, false)
for i, v in ipairs(findSystems(bootfs.address)) do
    table.insert(strs, v[1])
    table.insert(funcs, v[2])
end

---- systems on other disks
local addresses = {}
for address in component.list("filesystem", true) do
    if address ~= bootfs.address then
        table.insert(addresses, address)
    end
end
table.sort(addresses)
for _, address in ipairs(addresses) do
    local tbl = findSystems(address)
    if #tbl > 0 then
        table.insert(strs, "------ " .. getTitle(address))
        table.insert(funcs, false)
        for i, v in ipairs(tbl) do
            table.insert(strs, v[1])
            table.insert(funcs, v[2])
        end
    end
end

menu("likeOS/liked Boot Manager", strs, funcs, 3)