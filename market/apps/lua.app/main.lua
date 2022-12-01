local graphic = require("graphic")
local event = require("event")
local gui_container = require("gui_container")
local registry = require("registry")

local colors = gui_container.colors

--------------------------------

local screen = ...

local sizeX, sizeY = graphic.getResolution(screen)
local window = graphic.createWindow(screen, 1, 1, sizeX, sizeY)
local reader = window:read(1, sizeY, sizeX, colors.gray, colors.white, "lua: ")

local strs = {}

local function update()
    local title = "Lua"

    window:clear(colors.white)
    window:set(1, 1, colors.gray, colors.white, string.rep(" ", sizeX))
    window:set(math.floor(((sizeX / 2) - (#title / 2)) + 0.5), 1, colors.gray, colors.white, title)
    window:set(sizeX, 1, colors.red, colors.white, "X")

    for i, str in ipairs(strs) do
        local posY = sizeY - i
        if posY >= 2 then
            window:set(1, posY, colors.white, colors.black, str)
        end
    end

    reader.redraw()
end

update()

--------------------------------

while true do
    local eventData = {event.pull()}
    local windowEventData = window:uploadEvent(eventData)
    local readerData = reader.uploadEvent(eventData)

    if readerData and readerData ~= true then
        reader.setBuffer("")
        local code, err = load(readerData, "=lua", "t", setmetatable({_G = _G, screen = screen}, {__index = _G}))
        if code then
            local ok, err = pcall(code)
            if ok then
                if err then
                    table.insert(strs, 1, tostring(err))
                end
            else
                table.insert(strs, 1, err or "unknown error in runing code")
            end
        else
            table.insert(strs, 1, err or "unknown error in loading code")
        end
        update()
    end

    if windowEventData[1] == "touch" then
        if windowEventData[3] == sizeX and windowEventData[4] == 1 then
            break
        end
    end
end