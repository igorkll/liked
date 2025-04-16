local component = component or require("component") --openOS / native compatible
local computer = computer or require("computer")
local unicode = unicode or require("unicode")

--------------------------------------------

local internet = component.proxy(component.list("internet")() or error("no internet card", 0))
local likeScreen = ...
local gpu
local updateScreen
pcall(function()
    local graphic = require("graphic")
    gpu = graphic.findGpu(likeScreen)
    updateScreen = function()
        graphic.forceUpdate(likeScreen)
    end
end)
if not gpu then
    gpu = component.proxy(component.list("gpu")() or error("no gpu", 0))
end

--------------------------------------------

local screen = likeScreen or gpu.getScreen()
if not updateScreen and not screen then
    screen = component.list("screen")() or error("no screen", 0)
    gpu.bind(screen)
end

gpu.setBackground(0x000000)
gpu.setForeground(0xffffff)
local orx, ory = gpu.maxResolution()
local rx, ry = orx, ory
gpu.setResolution(math.min(rx, 80), math.min(ry, 25))
rx, ry = gpu.getResolution()
gpu.fill(1, 1, rx, ry, " ")

--------------------------------------------

local drive
pcall(function()
    drive = computer.getBootAddress() --в случаи с luabios если сменить EEPROM после запуска компьтера то данный метод вернет nil и строку об отсутвии компонента
end)
if not drive then                  --если через getBootAddress не получилось(например если чип EEPROM был сменен, в bios с которого произошла загрузка не может без него вернуть строку с адресом диска)
    pcall(function()
        drive = require("filesystem").get("/").address
    end)
end
if drive and not component.proxy(drive) then
    drive = nil
end

--------------------------------------------

local rx, ry = gpu.getResolution()
local centerY = math.floor(ry / 2)
local keyboards = component.invoke(screen, "getKeyboards")

local function isKeyboard(address)
    for i, v in ipairs(keyboards) do
        if v == address then
            return true
        end
    end
    return false
end

local function wget(url)
    local handle, err = internet.request(url)
    if handle then
        local data = {}
        while true do
            local result, reason = handle.read(math.huge)
            if result then
                table.insert(data, result)
            else
                handle.close()

                if reason then
                    return nil, reason
                else
                    return table.concat(data)
                end
            end
        end
    else
        return nil, tostring(err or "unknown error")
    end
end

--------------------------------------------

local function invertColor()
    gpu.setBackground(gpu.setForeground(gpu.getBackground()))
end

local function centerPrint(y, text)
    gpu.set(((rx / 2) - (unicode.len(text) / 2)) + 1, y, text)
end

local function screenFill(y)
    gpu.fill(8, y, rx - 15, 1, " ")
end

local function clearScreen()
    gpu.fill(1, 1, rx, ry, " ")
end

local function status(text)
    clearScreen()
    centerPrint(math.floor((ry / 2) + 0.5), text)
    if updateScreen then updateScreen() end
end

local function menu(label, lstrs, funcs, withoutBackButton, refresh)
    local selected = 1
    local strs = {}
    for i, v in ipairs(lstrs) do
        strs[i] = v
    end

    if not withoutBackButton then
        table.insert(strs, "back")
    end

    local function redraw()
        clearScreen()
        invertColor()
        centerPrint(2, label)
        invertColor()

        for i, str in ipairs(strs) do
            if i == selected then
                invertColor()
                screenFill(3 + i)
            end
            centerPrint(3 + i, str)
            if i == selected then invertColor() end
        end

        if updateScreen then updateScreen() end
    end
    redraw()

    while true do
        local eventData = { computer.pullSignal() }
        if eventData[1] == "key_down" and isKeyboard(eventData[2]) then
            if eventData[4] == 28 then
                if funcs[selected] then
                    if funcs[selected](strs[selected], eventData[5]) then
                        return true
                    else
                        if refresh then
                            local lstrs, lfuncs = refresh()
                            if not withoutBackButton then
                                table.insert(lstrs, "back")
                            end
                            strs = lstrs
                            funcs = lfuncs
                        end
                        redraw()
                    end
                else
                    break
                end
            elseif eventData[4] == 200 then
                selected = selected - 1
                if selected < 1 then
                    selected = 1
                else
                    redraw()
                end
            elseif eventData[4] == 208 then
                selected = selected + 1
                if selected > #strs then
                    selected = #strs
                else
                    redraw()
                end
            end
        end
    end
end

--------------------------------------------

local function serialize(value, pretty)
    local kw = {
        ["and"] = true,
        ["break"] = true,
        ["do"] = true,
        ["else"] = true,
        ["elseif"] = true,
        ["end"] = true,
        ["false"] = true,
        ["for"] = true,
        ["function"] = true,
        ["goto"] = true,
        ["if"] = true,
        ["in"] = true,
        ["local"] = true,
        ["nil"] = true,
        ["not"] = true,
        ["or"] = true,
        ["repeat"] = true,
        ["return"] = true,
        ["then"] = true,
        ["true"] = true,
        ["until"] = true,
        ["while"] = true
    }
    local id = "^[%a_][%w_]*$"
    local ts = {}
    local result_pack = {}
    local function recurse(current_value, depth)
        local t = type(current_value)
        if t == "number" then
            if current_value ~= current_value then
                table.insert(result_pack, "0/0")
            elseif current_value == math.huge then
                table.insert(result_pack, "math.huge")
            elseif current_value == -math.huge then
                table.insert(result_pack, "-math.huge")
            else
                table.insert(result_pack, tostring(current_value))
            end
        elseif t == "string" then
            table.insert(result_pack, (string.format("%q", current_value):gsub("\\\n", "\\n")))
        elseif
            t == "nil" or t == "boolean" or pretty and (t ~= "table" or (getmetatable(current_value) or {}).__tostring)
        then
            table.insert(result_pack, tostring(current_value))
        elseif t == "table" then
            if ts[current_value] then
                if pretty then
                    table.insert(result_pack, "recursion")
                    return
                else
                    error("tables with cycles are not supported")
                end
            end
            ts[current_value] = true
            local f
            if pretty then
                local ks, sks, oks = {}, {}, {}
                for k in pairs(current_value) do
                    if type(k) == "number" then
                        table.insert(ks, k)
                    elseif type(k) == "string" then
                        table.insert(sks, k)
                    else
                        table.insert(oks, k)
                    end
                end
                table.sort(ks)
                table.sort(sks)
                for _, k in ipairs(sks) do
                    table.insert(ks, k)
                end
                for _, k in ipairs(oks) do
                    table.insert(ks, k)
                end
                local n = 0
                f =
                    table.pack(
                        function()
                            n = n + 1
                            local k = ks[n]
                            if k ~= nil then
                                return k, current_value[k]
                            else
                                return nil
                            end
                        end
                    )
            else
                f = table.pack(pairs(current_value))
            end
            local i = 1
            local first = true
            table.insert(result_pack, "{")
            for k, v in table.unpack(f) do
                if not first then
                    table.insert(result_pack, ",")
                    if pretty then
                        table.insert(result_pack, "\n" .. string.rep(" ", depth))
                    end
                end
                first = nil
                local tk = type(k)
                if tk == "number" and k == i then
                    i = i + 1
                    recurse(v, depth + 1)
                else
                    if tk == "string" and not kw[k] and string.match(k, id) then
                        table.insert(result_pack, k)
                    else
                        table.insert(result_pack, "[")
                        recurse(k, depth + 1)
                        table.insert(result_pack, "]")
                    end
                    table.insert(result_pack, "=")
                    recurse(v, depth + 1)
                end
            end
            ts[current_value] = nil -- allow writing same table more than once
            table.insert(result_pack, "}")
        else
            error("unsupported type: " .. t)
        end
    end
    recurse(value, 1)
    local result = table.concat(result_pack)
    if pretty then
        local limit = type(pretty) == "number" and pretty or 10
        local truncate = 0
        while limit > 0 and truncate do
            truncate = string.find(result, "\n", truncate + 1, true)
            limit = limit - 1
        end
        if truncate then
            return result:sub(1, truncate) .. "..."
        end
    end
    return result
end

local function unserialize(data)
    local result, reason = load("return " .. data, "=unserialize", nil, { math = { huge = math.huge } })
    if not result then
        return nil, reason
    end

    local ok, output = pcall(result)
    if not ok then
        return nil, output
    end

    if type(output) == "table" then
        return output
    end
    return nil, "type error, input data is not a table"
end

--------------------------------------------

local baseUrl = "https://raw.githubusercontent.com/igorkll/liked/"
local branches = { "main", "test", "dev" }
local editions = { "full", "classic", "demo" }

local allowSaveOS = {
    ["full"] = true
}

local mainWarn = "ATTENTION, after installing this version of the system, other operating systems will not work on this device! if you want to install another OS in the future or another edition of liked, then you will have to change the EEPROM and format the disk. and only then will you be able to run the installer"
local warnOS = {
    ["classic"] = mainWarn,
    ["demo"] = mainWarn .. ". the demo version was created solely for familiarization with the system, computers on the demo version can be used as an advertising shield demonstrating the capabilities of the OS in public, this version is extremely unsuitable for use"
}

--------------------------------------------

local function segments(path)
    local parts = {}
    for part in path:gmatch("[^\\/]+") do
        local current, up = part:find("^%.?%.$")
        if current then
            if up == 2 then
                table.remove(parts)
            end
        else
            table.insert(parts, part)
        end
    end
    return parts
end

local function canonical(path)
    local result = table.concat(segments(path), "/")
    if unicode.sub(path, 1, 1) == "/" then
        return "/" .. result
    else
        return result
    end
end

local function fs_path(path)
    local parts = segments(path)
    local result = table.concat(parts, "/", 1, #parts - 1) .. "/"
    if unicode.sub(path, 1, 1) == "/" and unicode.sub(result, 1, 1) ~= "/" then
        return canonical("/" .. result)
    else
        return canonical(result)
    end
end

--------------------------------------------

local showWarn
local generateTitle

local function getBlackList(branch, edition)
    local editionInfo = assert(wget(baseUrl .. branch .. "/system/likedlib/sysmode/" .. edition .. ".reg"))
    if editionInfo then
        local tbl = unserialize(editionInfo)
        if tbl then
            return tbl.filesBlackList
        end
    end
end

local function getInstallData(branch, edition)
    return {
        data = { branch = branch, mode = edition },
        filesBlackList = getBlackList(branch, edition),
        label = "liked",
        noWait = true,
        noReboot = true,
        noSetBootaddress = true
    }
end

local function getInstallDataStr(branch, edition)
    return "local installdata = " .. serialize(getInstallData(branch, edition))
end

local function buildUpdater(branch, edition)
    return getInstallDataStr(branch, edition) ..
    "\n" .. assert(wget(baseUrl .. branch .. "/system/likedlib/update/update.lua"))
end

local function isOpenOS(address)
    return component.invoke(address, "exists", "/lib/core/boot.lua")
end

local function isMineOS(address)
    --return component.invoke(address, "exists", "/OS.lua")
    return false
end

local function downloadFile(diskProxy, branch, path, toPath)
    local content = assert(wget(baseUrl .. branch .. path))
    diskProxy.makeDirectory(fs_path(toPath))
    local file = diskProxy.open(toPath, "wb")
    diskProxy.write(file, content)
    diskProxy.close(file)
end

local function getRealTime(attemptTwo)
    local tmpfs = component.proxy(computer.tmpAddress())

    local file = assert(tmpfs.open("/null", "wb"))
    tmpfs.close(file)

    local unixTime = tmpfs.lastModified("/null")
    tmpfs.remove("/null")

    if not unixTime and not attemptTwo then
        tmpfs.remove("/")
        return getRealTime(true)
    end

    return unixTime
end

local function updateEepromApi(disk) --the new bios can store data in the EEPROM in a different way. and it is unknown how the old bios stores the data
    function computer.setBootAddress() end

    function computer.getBootAddress() return disk end
end

local function flashRestricted(disk, branch)
    local eeprom = component.proxy(component.list("eeprom")() or "")
    if eeprom then
        local appendData = "local bootAddress = \"" .. disk .. "\"\n"
        local diskProxy = component.proxy(disk)
        local file = diskProxy.open("/system/sysdata/eeprom", "wb")
        diskProxy.write(file, eeprom.address)
        diskProxy.close(file)

        eeprom.setData(tostring(getRealTime()))
        eeprom.setLabel(assert(wget(baseUrl .. branch .. "/system/firmware/restricted_loader/label.txt")))
        eeprom.set(appendData .. assert(wget(baseUrl .. branch .. "/system/firmware/restricted_loader/code.lua")))
        eeprom.makeReadonly(eeprom.getChecksum())

        updateEepromApi(disk)
    end
end

local function install(disk, branch, edition, doOpenOS, doMineOS, otherDevice)
    local diskProxy = component.proxy(disk)
    local flashRestrictedFlag = edition ~= "full"

    if doOpenOS then
        diskProxy.rename("/init.lua", "/openOS.lua")
        downloadFile(diskProxy, branch, "/market/apps/openOS.app/actions.cfg", "/vendor/apps/openOS.app/actions.cfg")
        downloadFile(diskProxy, branch, "/market/apps/openOS.app/icon.t2p", "/vendor/apps/openOS.app/icon.t2p")
        downloadFile(diskProxy, branch, "/market/apps/openOS.app/lua5_2.lua", "/vendor/apps/openOS.app/lua5_2.lua")
        downloadFile(diskProxy, branch, "/market/apps/openOS.app/main.lua", "/vendor/apps/openOS.app/main.lua")
        downloadFile(diskProxy, branch, "/market/apps/openOS.app/uninstall.lua", "/vendor/apps/openOS.app/uninstall.lua")
    end

    if doMineOS then
        downloadFile(diskProxy, branch, "/market/apps/mineOS.app/LICENSE", "/vendor/apps/mineOS.app/LICENSE")
        downloadFile(diskProxy, branch, "/market/apps/mineOS.app/actions.cfg", "/vendor/apps/mineOS.app/actions.cfg")
        downloadFile(diskProxy, branch, "/market/apps/mineOS.app/icon.t2p", "/vendor/apps/mineOS.app/icon.t2p")
        downloadFile(diskProxy, branch, "/market/apps/mineOS.app/lua5_2.lua", "/vendor/apps/mineOS.app/lua5_2.lua")
        downloadFile(diskProxy, branch, "/market/apps/mineOS.app/main.lua", "/vendor/apps/mineOS.app/main.lua")
        downloadFile(diskProxy, branch, "/market/apps/mineOS.app/uninstall.lua", "/vendor/apps/mineOS.app/uninstall.lua")
        downloadFile(diskProxy, branch, "/market/apps/mineOS.app/mineOS.lua", "/mineOS.lua")
    end

    assert(load(buildUpdater(branch, edition), "=updater", nil, _G))(disk)
    if otherDevice then
        gpu.setBackground(0x000000)
        gpu.setForeground(0xffffff)
        gpu.setResolution(rx, ry)
        gpu.fill(1, 1, rx, ry, " ")
        showWarn("liked-" .. branch .. "-" .. edition .. " has been successfully installed on the " .. generateTitle(disk) .. " disk", " DONE ")
    else
        if flashRestrictedFlag then
            flashRestricted(disk, branch)
        end

        pcall(computer.setBootAddress, disk)
        pcall(computer.shutdown, "fast")
    end
end

--------------------------------------------

function generateTitle(address)
    local title = address:sub(1, 8) .. "-" .. (component.invoke(address, "getLabel") or "no label")
    if address == drive then
        title = title .. " (self disk)"
    end
    return title
end

local function openOSMineOSStr(openOS, mineOS)
    if openOS and mineOS then
        return "save 'openOS & mineOS'"
    elseif openOS then
        return "save 'openOS'"
    elseif mineOS then
        return "save 'mineOS'"
    end
end

local function toParts(tool, str, max)
    local strs = {}
    while tool.len(str) > 0 do
        table.insert(strs, tool.sub(str, 1, max))
        str = tool.sub(str, tool.len(strs[#strs]) + 1)
    end
    return strs
end

function showWarn(str, title)
    clearScreen()
    invertColor()
    centerPrint(2, title or " WARNING ")
    invertColor()
    centerPrint(ry - 1, "press enter to continue")

    for i, v in ipairs(toParts(string, str, rx - 4)) do
        centerPrint(3 + i, v)
    end

    if updateScreen then updateScreen() end

    while true do
        local eventData = { computer.pullSignal() }
        if eventData[1] == "key_down" and isKeyboard(eventData[2]) then
            if eventData[4] == 28 then
                break
            end
        end
    end
end

local function generateFunction(address)
    local title = generateTitle(address)
    return function()
        local funcs = {}
        for _, branch in ipairs(branches) do
            table.insert(funcs, function()
                local funcs = {}
                for _, edition in ipairs(editions) do
                    table.insert(funcs, function()
                        local funcs = {}
                        for i = 1, 2 do
                            table.insert(funcs, function()
                                if warnOS[edition] then
                                    showWarn(warnOS[edition])
                                end

                                local openOS, mineOS, saveSystemStr
                                if allowSaveOS[edition] then
                                    openOS, mineOS = isOpenOS(address), isMineOS(address)
                                    saveSystemStr = openOSMineOSStr(openOS, mineOS)
                                end

                                local strs, funcs = { "format disk" }, { function()
                                    status("installation...")
                                    component.invoke(address, "remove", "/")
                                    install(address, branch, edition, nil, nil, i == 2)
                                    return true
                                end }

                                if saveSystemStr then
                                    table.insert(strs, saveSystemStr)
                                    table.insert(funcs, function()
                                        status("installation...")
                                        install(address, branch, edition, openOS, mineOS, i == 2)
                                        return true
                                    end)
                                end

                                if menu(title .. " | installation options", strs, funcs) then
                                    return true
                                end
                            end)
                        end
                        if menu(title .. " | where the OS will be used (important)", {
                                "on this device (flash the EEPROM if necessary and reboot into the system)",
                                "on another device (do not flash the EEPROM and do not turn off the device)"
                            }, funcs) then
                            return true
                        end
                    end)
                end
                if menu(title .. " | select edition", editions, funcs) then
                    return true
                end
            end)
        end
        if menu(title .. " | select branch", branches, funcs) then
            return true
        end
    end
end

local function isAllowedDisk(address)
    return address ~= computer.tmpAddress() and not component.invoke(address, "isReadOnly")
end

local function generateList()
    local strs, funcs = {}, {}
    if drive and isAllowedDisk(drive) then
        table.insert(strs, generateTitle(drive))
        table.insert(funcs, generateFunction(drive))
    end
    for address in component.list("filesystem", true) do
        if address ~= drive and isAllowedDisk(address) then
            table.insert(strs, generateTitle(address))
            table.insert(funcs, generateFunction(address))
        end
    end
    return strs, funcs
end

--------------------------------------------

menu("liked & likeOS - web installer", generateList())

gpu.setBackground(0x000000)
gpu.setForeground(0xffffff)
gpu.setResolution(orx, ory)
gpu.fill(1, 1, orx, ory, " ")
pcall(function()
    require("term").clear()
end)
if updateScreen then updateScreen() end
