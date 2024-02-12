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
            return getGPU(screen)
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

local function bootTo(address, path, args)
    
end

local function findLikeosBasedSystems()
    
end

local function menu(label, strs, funcs, autoTimeout)
    local selected = 1
    local startTime = computer.uptime()

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
            gpu.set(2, ry, "Enter=Choose  ◢◣-UP  ◥◤-DOWN")

            invert(gpu)

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
                if funcs[selected](strs[selected], eventData[5]) then
                    break
                end
            elseif eventData[4] == 200 then
                autoTimeout = nil
                selected = selected - 1
                if selected < 1 then
                    selected = 1
                    if oldAutotimeExists then
                        redraw()
                    end
                else 
                    redraw()
                end
            elseif eventData[4] == 208 then
                autoTimeout = nil
                selected = selected + 1
                if selected > #strs then
                    selected = #strs
                    if oldAutotimeExists then
                        redraw()
                    end
                else
                    redraw()
                end
            end
        end

        if autoTimeout then
            if getAutotime() <= 0 then
                redraw(0)
                return 1
            end
            redraw()
        end
    end
end

--------------------------------

for gpu in screens() do
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

menu("LikeOS Boot Manager", strs, funcs, 3)