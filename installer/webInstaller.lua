local component = component or require("component") --openOS / native compatible
local computer = computer or require("computer")
local unicode = unicode or require("unicode")

--------------------------------------------

local gpu = component.proxy(component.list("gpu")() or error("no gpu", 0))
local internet = component.proxy(component.list("internet")() or error("no internet card", 0))

--------------------------------------------

local screen = gpu.getScreen()
if not screen then
    screen = component.list("screen")() or error("no screen", 0)
    gpu.bind(screen)
end

gpu.setBackground(0x000000)
gpu.setForeground(0xffffff)
local rx, ry = gpu.maxResolution()
gpu.setResolution(math.min(rx, 80), math.min(ry, 25))
rx, ry = gpu.getResolution()
gpu.fill(1, 1, rx, ry, " ")

--------------------------------------------

local drive
pcall(function ()
    drive = computer.getBootAddress() --в случаи с luabios если сменить EEPROM после запуска компьтера то данный метод вернет nil и строку об отсутвии компонента
end)
if not drive then --если через getBootAddress не получилось(например если чип EEPROM был сменен, в bios с которого произошла загрузка не может без него вернуть строку с адресом диска)
    pcall(function ()
        drive = require("filesystem").get("/").address
    end)
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
end

local function menu(label, lstrs, funcs, withoutBackButton, refresh)
    local selected = 1
    local strs = {}
    for i, v in ipairs(lstrs) do
        strs[i] = v
    end

    if not withoutBackButton then
        table.insert(strs, "Back")
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
    end
    redraw()

    while true do
        local eventData = {computer.pullSignal()}
        if eventData[1] == "key_down" and isKeyboard(eventData[2]) then
            if eventData[4] == 28 then
                if funcs[selected] then
                    if funcs[selected](strs[selected], eventData[5]) then
                        break
                    else
                        if refresh then
                            local lstrs, lfuncs = refresh()
                            if not withoutBackButton then
                                table.insert(lstrs, "Back")
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
    local result, reason = load("return " .. data, "=unserialize", nil, {math = {huge = math.huge}})
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
local branches = {"main", "test", "dev"}
local editions = {"full", "classic", "demo"}

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
    return {data = {branch = branch, mode = edition}, filesBlackList = getBlackList(branch, edition), label = "liked", noWait = true}
end

local function getInstallDataStr(branch, edition)
    return "local installdata = " .. serialize(getInstallData(branch, edition))
end

local function buildUpdater(branch, edition)
    return getInstallDataStr(branch, edition) .. "\n" .. assert(wget(baseUrl .. branch .. "/system/likedlib/update/update.lua"))
end

local function isOpenOS(address)
    return component.invoke(address, "exists", "/lib/core/boot.lua")
end

local function isMineOS(address)
    return component.invoke(address, "exists", "/OS.lua")
end

local function downloadFile(diskProxy, branch, path, toPath)
    local content = assert(wget(baseUrl .. branch .. path))
    diskProxy.makeDirectory(fs_path(toPath))
    local file = diskProxy.open(toPath, "wb")
    diskProxy.write(file, content)
    diskProxy.close(file)
end

local function install(disk, branch, edition, doOpenOS, doMineOS)
    local diskProxy = component.proxy(disk)

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

        local eeprom = component.proxy(component.list("eeprom")() or "")
        if eeprom then
            eeprom.setData("")
            eeprom.setLabel(assert(wget(baseUrl .. branch .. "/system/firmware/likeloader/label.txt")))
            eeprom.set(assert(wget(baseUrl .. branch .. "/system/firmware/likeloader/code.lua")))
        end
    end

    assert(load(buildUpdater(branch, edition), "=updater", nil, _G))(disk)
    if computer.setBootAddress then
        pcall(computer.setBootAddress, disk)
    else
        local eeprom = component.proxy(component.list("eeprom")() or "")
        if eeprom then
            eeprom.setData(disk) --потому что в mineOS нет функции computer.setBootAddress
        end
    end
    pcall(computer.shutdown, "fast")
end

--------------------------------------------

local function generateTitle(address)
    return address:sub(1, 8) .. "-" .. (component.invoke(address, "getLabel") or "no label")
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

local function generateFunction(address)
    local title = generateTitle(address)
    return function ()
        local funcs = {}
        for _, branch in ipairs(branches) do
            table.insert(funcs, function ()
                local funcs = {}
                for _, edition in ipairs(editions) do
                    table.insert(funcs, function ()
                        local openOS, mineOS = isOpenOS(address), isMineOS(address)
                        local omStr = openOSMineOSStr(openOS, mineOS)

                        local strs, funcs = {"format disk"}, {function ()
                            status("installation...")
                            component.invoke(address, "remove", "/")
                            install(address, branch, edition)
                        end}

                        if omStr then
                            table.insert(strs, omStr)
                            table.insert(funcs, function ()
                                status("installation...")
                                install(address, branch, edition, openOS, mineOS)
                            end)
                        end

                        menu(title .. " | installation options", strs, funcs)
                    end)
                end
                menu(title .. " | select edition", editions, funcs)
            end)
        end
        menu(title .. " | select branch", branches, funcs)
    end
end

local function generateList()
    local strs, funcs = {}, {}
    if drive then
        table.insert(strs, generateTitle(drive))
        table.insert(funcs, generateFunction(drive))
    end
    for address in component.list("filesystem", true) do
        if address ~= drive then
            table.insert(strs, generateTitle(address))
            table.insert(funcs, generateFunction(address))
        end
    end
    return strs, funcs
end

--------------------------------------------

menu("liked & likeOS - web installer", generateList())