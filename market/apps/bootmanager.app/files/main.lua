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
    local tbl = {}
    for address in component.list("gpu", true) do
        tbl[address] = getGPU(address)
    end
    return pairs(tbl)
end

