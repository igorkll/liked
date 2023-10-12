local component = require("component")
local bootloader = require("bootloader")
local gui_container = require("gui_container")
local colors = gui_container.colors
local graphic = require("graphic")
local system = require("system")
local paths = require("paths")
local event = require("event")
local thread = require("thread")
local gui = require("gui")
local uix = require("uix")
local fs = require("filesystem")

local hx, hy, hz = 48, 32, 48
local hologramsPath = paths.concat(paths.path(system.getSelfScriptPath()), "holograms")

local screen = ...
local rx, ry = graphic.getResolution(screen)
local window = graphic.createWindow(screen, 1, 1, rx, ry)
local layout = uix.create(window, colors.black)

local holo = gui.selectcomponent(screen, nil, nil, {"hologram"}, true)
if holo then
    holo = component.proxy(holo)
else
    return
end

local colorsCount = holo.maxDepth() == 2 and 3 or 1
local function col(index)
    if index > colorsCount then
        return 1
    end
end

if not _G.holo_agent then _G.holo_agent = {} end
if not _G.holo_agent[holo.address] then _G.holo_agent[holo.address] = {} end
local agent = _G.holo_agent[holo.address]

------------------------------------------------

local hologramsPaths = {}
for _, name in ipairs(fs.list(hologramsPath)) do
    hologramsPaths[paths.hideExtension(name)] = paths.concat(hologramsPath, name)
end

local baseTh = thread.current()
layout:createUpBar("Hologram").close.onClick = function ()
    baseTh:kill()
end

for i = 1, colorsCount do
    layout:createButton(rx - 16, (i * 2) + 1, 16, 1, holo.getPaletteColor(i), colors.gray, "color" .. i, true).onClick = function (self)
        local color = gui.selectfullcolor(screen)
        if color then
            holo.setPaletteColor(i, color)
            self.back = color
            self.fore2 = color
        end
        layout:draw()
    end
end

local switchI = 0
local switchs = {}
for name, path in pairs(hologramsPaths) do
    local switch = layout:createSwitch(2, 3 + switchI, agent.current == name)
    layout:createText(10, 3 + switchI, colors.white, name)
    table.insert(switchs, switch)
    function switch:onSwitch()
        if self.state then
            for _, lswitch in ipairs(switchs) do
                if lswitch ~= self and lswitch.state then
                    lswitch.state = false
                    lswitch:draw()
                end
            end
            
            holo.clear()
            agent.current = name
            if agent.th then
                agent.th:kill()
                agent.th = nil
            end

            local env = bootloader.createEnv()
            env.hx = hx
            env.hy = hy
            env.hz = hz
            env.col = col
            agent.th = thread.createBackground(assert(loadfile(path, nil, env)), holo)
            agent.th:resume()
        else
            holo.clear()
            agent.current = name
            if agent.th then
                agent.th:kill()
                agent.th = nil
            end
        end
    end
    switchI = switchI + 2
end

layout:draw()

while true do
    local eventData = {event.pull()}
    layout:uploadEvent(eventData)
end