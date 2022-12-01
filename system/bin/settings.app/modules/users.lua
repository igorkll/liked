local graphic = require("graphic")
local fs = require("filesystem")
local gui_container = require("gui_container")
local paths = require("paths")
local unicode = require("unicode")
local event = require("event")
local calls = require("calls")
local computer = require("computer")

local colors = gui_container.colors

------------------------------------

local screen, posX, posY = ...
local gpu = graphic.findGpu(screen)
local rx, ry = gpu.getResolution()

local wallpapersPath = "/system/wallpapers"

------------------------------------

local selectWindow = graphic.createWindow(screen, posX, posY, rx - (posX - 1), ry - (posY - 1))
local selected = 1

------------------------------------

local users = {}

local function draw()
    users = {}

    selectWindow:clear(colors.black)
    selectWindow:set(1, 1, colors.lightGray, colors.black, "     user add     ")
    selectWindow:set(1, 2, colors.black, colors.lightGray, "------------------")
    selectWindow:setCursor(1, 3)
    for i, user in ipairs({computer.users()}) do
        selectWindow:write(user .. "\n", colors.black, colors.green)
        table.insert(users, user)
    end
end

draw()

------------------------------------

return function(eventData)
    local selectWindowEventData = selectWindow:uploadEvent(eventData)

    if selectWindowEventData[1] == "touch" then
        local posY = selectWindowEventData[4] - 2

        if users[posY] then
            if gui_yesno(screen, nil, nil, "remove user \"" .. users[posY] .. "\"?") and selectWindowEventData[3] >= 1 and selectWindowEventData[3] <= 18 then
                computer.removeUser(users[posY])
            end
            draw()
        elseif selectWindowEventData[4] == 1 and selectWindowEventData[3] >= 1 and selectWindowEventData[3] <= 18 then
            local name = gui_input(screen, nil, nil, "user name")
            if name then
                local ok, err = computer.addUser(name)
                if not ok then
                    gui_warn(screen, nil, nil, err or "unknown")
                end
            end
            draw()
        end
    end
end