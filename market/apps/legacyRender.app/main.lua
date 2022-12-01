local graphic = require("graphic")
local event = require("event")
local gui_container = require("gui_container")
local registry = require("registry")

local colors = gui_container.colors

--------------------------------

local screen = ...

if not graphic.isBufferAvailable() then
    gui_warn(screen, nil, nil, "your version of open computers does not allow the use of advanced rendering, legacy rendering works by default")
    return
end

local sizeX, sizeY = graphic.getResolution(screen)
local window = graphic.createWindow(screen, 1, 1, sizeX, sizeY)

local function update()
    local title = "Legacy Render"

    window:clear(colors.white)
    window:set(1, 1, colors.gray, colors.white, string.rep(" ", sizeX))
    window:set(math.floor(((sizeX / 2) - (#title / 2)) + 0.5), 1, colors.gray, colors.white, title)
    window:set(sizeX, 1, colors.red, colors.white, "X")

    window:fill(2, 3, 32, 1, graphic.allowBuffer and colors.red or colors.green, 0, " ")
    window:set(2, 3,
    graphic.allowBuffer and colors.red or colors.green,
    graphic.allowBuffer and colors.black or colors.white,
    "render mode: " .. (graphic.allowBuffer and "advanced" or "legacy"))
end

update()

--------------------------------

while true do
    local eventData = {event.pull()}
    local windowEventData = window:uploadEvent(eventData)

    if windowEventData[1] == "touch" then
        if windowEventData[3] == sizeX and windowEventData[4] == 1 then
            break
        end
        if windowEventData[3] >= 2 and windowEventData[3] <= 34 and windowEventData[4] == 3 then
            graphic.setAllowBuffer(not graphic.allowBuffer)
            registry.legacyRender = not graphic.allowBuffer
            update()
        end
    end
end