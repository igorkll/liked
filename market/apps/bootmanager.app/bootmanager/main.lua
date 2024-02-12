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

local function menu(label, strs, funcs, autoTimeout)
    local selected = 1
    local startTime = computer.uptime()

    local function redraw(otherTime)
        for gpu in screens() do
            local rx, ry = gpu.getResolution()
            gpu.fill(1, 1, rx, ry, " ")

            invert(gpu)

            gpu.fill(1, 1, rx, 1, " ")
            centerPrint(gpu, 1, label)

            gpu.fill(1, ry, rx, 1, " ")
            gpu.set(2, ry, "Enter=Choose  ↑-UP  ↓-DOWN")

            invert(gpu)

            gpu.set(2, ry - 3, "autorun of the selected system after: " .. math.floor(otherTime or (autoTimeout - (computer.uptime() - selected))))
        end
    end
    redraw()

    while true do
        local eventData = {computer.pullSignal(autoTimeout and 0.5)}
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
                else 
                    redraw()
                end
            elseif eventData[4] == 208 then
                autoTimeout = nil
                selected = selected + 1
                if selected > #strs then
                    selected = #strs
                else
                    redraw()
                end
            end
        end

        if autoTimeout then
            if autoTimeout - (computer.uptime() - selected) <= 0 then
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

menu("Like Boot-Manager", strs, funcs, 3)