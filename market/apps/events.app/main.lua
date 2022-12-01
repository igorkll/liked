local graphic = require("graphic")
local event = require("event")
local gui_container = require("gui_container")
local registry = require("registry")

local colors = gui_container.colors

--------------------------------

local screen = ...

local oldAllowBuffer = graphic.getBufferStateOnScreen(screen)
graphic.setBufferStateOnScreen(screen, false)

local sizeX, sizeY = graphic.getResolution(screen)
local window = graphic.createWindow(screen, 1, 1, sizeX, sizeY)

local function update()
    local title = "Events"

    window:clear(colors.black)
    window:set(1, 1, colors.gray, 0, string.rep(" ", sizeX))
    window:set(math.floor(((sizeX / 2) - (#title / 2)) + 0.5), 1, colors.gray, colors.lightGray, title)
    window:set(sizeX, 1, colors.blue, colors.white, "X")
end

update()

--------------------------------

while true do
    local eventData = {event.pull()}
    local windowEventData = window:uploadEvent(eventData)

    local output = {}
    for k, v in pairs(eventData) do
        eventData[k] = tostring(v)
    end
    output = table.concat(eventData, "  ")

    window:copy(1, 3, sizeX, sizeY - 2, 0, -1)
    window:set(1, sizeY, colors.black, colors.blue, string.rep(" ", sizeX))
    window:set(1, sizeY, colors.black, colors.blue, output)

    if windowEventData[1] == "touch" then
        if windowEventData[3] == sizeX and windowEventData[4] == 1 then
            graphic.setBufferStateOnScreen(screen, oldAllowBuffer)
            break
        end
    end
end