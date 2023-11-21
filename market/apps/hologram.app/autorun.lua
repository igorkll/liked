local thread = require("thread")
local component = require("component")
local registry = require("registry")
local bootloader = require("bootloader")
local system = require("system")
local paths = require("paths")

local hx, hy, hz = 48, 32, 48

if registry.holo then
    if not _G.holo_agent then
        _G.holo_agent = {}
    end

    for addr in component.list("hologram", true) do
        if registry.holo[addr] then
            local holo = component.proxy(addr)
            
            _G.holo_agent[holo.address] = registry.holo[addr]
            local agent = _G.holo_agent[holo.address]

            if agent.current then
                local function col(index)
                    if index > agent.colorsCount then
                        return 1
                    end
                    return index
                end

                local env = bootloader.createEnv()
                env.hx = hx
                env.hy = hy
                env.hz = hz
                env.col = col
                env.colorsCount = agent.colorsCount
                agent.th = thread.createBackground(assert(loadfile(system.getResourcePath(paths.concat("holograms", agent.current .. ".lua")), nil, env)), holo)
                agent.th:resume()
            end
        end
    end
end