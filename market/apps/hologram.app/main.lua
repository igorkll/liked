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

local baseTh = thread.current()
layout:createUpBar("Hologram").close.onClick = function ()
    baseTh:kill()
end
layout:draw()

while true do
    local eventData = {event.pull()}
    layout:uploadEvent(eventData)
end