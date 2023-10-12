local component = require("component")
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

if not _G.holo_agent then _G.holo_agent = {} end
_G.holo_agent[holo.address] = {}
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

for i = 1, holo.maxDepth() == 2 and 3 or 1 do
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
            agent.current = name
            agent.th = thread.createBackground(assert(loadfile(path, nil, _ENV)))
        else
            agent.current = nil
            agent.th:kill()
            agent.th = nil
        end
    end
    switchI = switchI + 2
end

layout:draw()

while true do
    require("computer").beep()
    local eventData = {event.pull()}
    layout:uploadEvent(eventData)
end