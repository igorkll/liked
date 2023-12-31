--local installdata = {data={branch="main",mode="full"}} --пристыковываеться к скрипту на этапе обновления

local function initScreen(gpu, screen)
    if gpu.getScreen() ~= screen then
        gpu.bind(screen, false)
    end
    gpu.setDepth(1)
    gpu.setDepth(gpu.maxDepth())
    gpu.setResolution(50, 16)
    gpu.setBackground(0)
    gpu.setForeground(0xFFFFFF)
    gpu.fill(1, 1, 50, 16, " ")
end

local function centerPrint(gpu, text, y)
    local rx, ry = gpu.getResolution()
    gpu.set((math.floor(rx / 2) - (#text / 2)) + 1, y, text)
end

local screensInited
local function printState(num)
    local str = "working with updates: " .. tostring(math.floor((num * 100) + 0.5)) .. "%"
    local gpu = component.proxy(component.list("gpu")() or "")
    if gpu then
        for screen in component.list("screen") do
            if not screensInited then
                initScreen(gpu, screen)

                if gpu.getDepth() > 1 then
                    gpu.setPaletteColor(0, 0x5bb9f0)
                    gpu.setPaletteColor(1, 0xffffff)

                    gpu.setBackground(0, true)
                    gpu.setForeground(1, true)
                else
                    gpu.setBackground(0xFFFFFF)
                    gpu.setForeground(0x000000)
                end
            elseif gpu.getScreen() ~= screen then
                gpu.bind(screen, false)
            end

            local rx, ry = gpu.getResolution()
            gpu.fill(1, 1, rx, ry, " ")
            centerPrint(gpu, str, math.floor(ry / 2))
            centerPrint(gpu, "please do not turn off the device!", ry - 1)
        end
        screensInited = true
    end
end

printState(0)

--------------------------------

local internet = component.proxy(component.list("internet")() or error("no internet card found", 0))
local proxy = component.proxy(computer.getBootAddress())

local function getInternetFile(url)
    local handle, data, result, reason = internet.request(url), ""
    if handle then
        while true do
            result, reason = handle.read(math.huge) 
            if result then
                data = data .. result
            else
                handle.close()
                
                if reason then
                    return nil, reason
                else
                    return data
                end
            end
        end
    else
        return nil, "unvalid address"
    end
end

local function split(str, sep)
    local parts, count, i = {}, 1, 1
    while 1 do
        if i > #str then break end
        local char = str:sub(i, #sep + (i - 1))
        if not parts[count] then parts[count] = "" end
        if char == sep then
            count = count + 1
            i = i + #sep
        else
            parts[count] = parts[count] .. str:sub(i, i)
            i = i + 1
        end
    end
    if str:sub(#str - (#sep - 1), #str) == sep then table.insert(parts, "") end
    return parts
end

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

local function saveFile(path, data)
    proxy.makeDirectory(fs_path(path))
    local file = proxy.open(path, "wb")
    proxy.write(file, data)
    proxy.close(file)
end

local function inBlackList(path)
    path = canonical(path)
    if installdata.filesBlackList then
        for i, blackpath in ipairs(installdata.filesBlackList) do
            if canonical(blackpath) == path then
                return true
            end
        end
    end
end

local function installUrl(urlPart, state2)
    local filelist = split(assert(getInternetFile(urlPart .. "/installer/filelist.txt")), "\n")
    local count = 0
    for i, v in ipairs(filelist) do
        if v ~= "" and not inBlackList(v) then
            local filedata = assert(getInternetFile(urlPart .. v))

            if count % 5 == 0 then
                printState((((i - 1) / (#filelist - 1)) / 2) + (state2 and 0.5 or 0))
            end

            saveFile(v, filedata)
            count = count + 1
        end
    end
end

--удаляем старую систему во избежании конфликта версий
proxy.remove("/system")

--сначала ставим liked а только потом ядро, чтобы не перезаписывать init.lua раньше времени. чтобы если обновления оборветься то система не окирпичилась
installUrl("https://raw.githubusercontent.com/igorkll/liked/" .. installdata.data.branch)
installUrl("https://raw.githubusercontent.com/igorkll/likeOS/" .. installdata.data.branch, true)

--востанавливаем содержимое sysdata
for name, content in pairs(installdata.data) do
    saveFile("/system/sysdata/" .. name, content)
end

--удаляем этот файл
proxy.remove("/likeOS_startup.lua")

--перезагружаем устройтсво
computer.shutdown("fast")