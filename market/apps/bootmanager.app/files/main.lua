local function getGPU(screen)
    for address in component.list("gpu", true) do
        if component.invoke(address, "getScreen") == screen then
            return component.proxy(address)
        end
    end
    local gpu = component.proxy(component.list("gpu", true)() or "")
    if gpu then
        gpu.bind(screen, true)
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
end

