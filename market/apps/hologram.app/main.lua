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
local crx, cry = rx / 2, ry / 2
local window = graphic.createWindow(screen, 1, 1, rx, ry)
local layout = uix.create(window, colors.black)

local holo = gui.selectcomponent(screen, nil, nil, {"hologram"}, true)
if holo then
    holo = component.proxy(holo)
else
    return
end

local colorsCount = holo.maxDepth() == 2 and 3 or 1
local maxScale = colorsCount == 3 and 4 or 3
local maxTranslation = colorsCount == 3 and 0.25 or 5
local minScale = 0.33

local function col(index)
    if index > colorsCount then
        return 1
    end
    return index
end

if not _G.holo_agent then _G.holo_agent = {} end
if not _G.holo_agent[holo.address] then _G.holo_agent[holo.address] = {} end
local agent = _G.holo_agent[holo.address]

local function updateRotation()
    if agent.useSpeed then
        pcall(holo.setRotationSpeed, agent.rotation, 0, 1, 0)
        pcall(holo.setRotation, 0, 0, 0, 0)
    else
        pcall(holo.setRotationSpeed, 0, 0, 0, 0)
        pcall(holo.setRotation, agent.rotation, 0, 1, 0)
    end
end

if not agent.rotation then
    agent.rotation = 0
    agent.useSpeed = false
end

------------------------------------------------

local hologramsPaths = {}
for _, name in ipairs(fs.list(hologramsPath)) do
    hologramsPaths[paths.hideExtension(name)] = paths.concat(hologramsPath, name)
end

local baseTh = thread.current()
layout:createUpBar("Hologram").close.onClick = function ()
    baseTh:kill()
end

local tx, ty, tz = holo.getTranslation()

layout:createText(2, ry - 7, nil, "shift x:")
local offsetX = layout:createSeek(11, ry - 7, crx - 11, nil, nil, nil, math.map(tx, -maxTranslation, maxTranslation, 0, 1))
function offsetX:onSeek(value)
    local x, y, z = holo.getTranslation()
    holo.setTranslation(math.map(value, 0, 1, -maxTranslation, maxTranslation), y, z)
end

layout:createText(2, ry - 5, nil, "shift y:")
local offsetY = layout:createSeek(11, ry - 5, crx - 11, nil, nil, nil, math.map(ty, 0, maxTranslation * 2, 0, 1))
function offsetY:onSeek(value)
    local x, y, z = holo.getTranslation()
    holo.setTranslation(x, math.map(value, 0, 1, 0, maxTranslation * 2), z)
end

layout:createText(2, ry - 3, nil, "shift z:")
local offsetZ = layout:createSeek(11, ry - 3, crx - 11, nil, nil, nil, math.map(tz, -maxTranslation, maxTranslation, 0, 1))
function offsetZ:onSeek(value)
    local x, y, z = holo.getTranslation()
    holo.setTranslation(x, y, math.map(value, 0, 1, -maxTranslation, maxTranslation))
end

layout:createText(2, ry - 1, nil, "scale:")
local scaleS = layout:createSeek(9, ry - 1, crx - 9, nil, nil, nil, math.map(holo.getScale(), minScale, maxScale, 0, 1))
function scaleS:onSeek(value)
    holo.setScale(math.map(value, 0, 1, minScale, maxScale))
end

layout:createButton(2, ry - 9, 21, 1, nil, nil, "reset scale/shift").onClick = function ()
    holo.setScale(1)
    holo.setTranslation(0, 0, 0)

    scaleS.value = math.map(holo.getScale(), minScale, maxScale, 0, 1)
    scaleS:draw()

    offsetX.value = 0.5
    offsetX:draw()

    offsetY.value = 0
    offsetY:draw()

    offsetZ.value = 0.5
    offsetZ:draw()
end










layout:createText(crx + 8, ry - 7, nil, "auto rotation")
local useSpeedSwitch = layout:createSwitch(crx + 1, ry - 7, agent.useSpeed)
function useSpeedSwitch:onSwitch()
    agent.useSpeed = self.state
    updateRotation()
end

layout:createText(crx + 1, ry - 5, nil, "rotation:")
local rotationSeek = layout:createSeek(crx + 11, ry - 5, crx - 11, nil, nil, nil, math.map(agent.rotation, -180, 180, 0, 1))
function rotationSeek:onSeek(value)
    agent.rotation = math.map(value, 0, 1, -180, 180)
    updateRotation()
end

layout:createButton(crx + 1, ry - 9, 21, 1, nil, nil, "reset rotation").onClick = function ()
    agent.rotation = 0
    agent.rotationSpeed = 0
    agent.useSpeed = false

    useSpeedSwitch.state = false
    useSpeedSwitch:draw()

    rotationSeek.value = 0.5
    rotationSeek:draw()

    updateRotation()
end

for i = 1, colorsCount do
    layout:createButton(rx - 16, (i * 2) + 1, 16, 1, holo.getPaletteColor(i), nil, "color" .. i, true).onClick = function (self)
        local color = gui.selectfullcolor(screen)
        if color then
            holo.setPaletteColor(i, color)
            uix.doColor(self, color)
            self.back2 = self.fore
            self.fore2 = self.back
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
            env.colorsCount = colorsCount
            agent.th = thread.createBackground(assert(loadfile(path, nil, env)), holo)
            agent.th:resume()
        else
            holo.clear()
            agent.current = nil
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