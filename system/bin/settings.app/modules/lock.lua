local graphic = require("graphic")
local fs = require("filesystem")
local gui_container = require("gui_container")
local paths = require("paths")
local unicode = require("unicode")
local event = require("event")
local calls = require("calls")
local sha256 = require("sha256").sha256

local colors = gui_container.colors

------------------------------------

local screen, posX, posY = ...
local gpu = graphic.findGpu(screen)
local rx, ry = gpu.getResolution()

local passwordPath = "/data/password.sha256"

local function checkPassword()
    if fs.exists(passwordPath) then
        local file = fs.open(passwordPath, "rb")
        local data = file.readAll()
        file.close()
        
        local password = gui_input(screen, nil, nil, "enter current password", true)

        if password then
            if sha256(password) == data then
                return true
            else
                gui_warn(screen, nil, nil, "uncorrent password")
            end
        end
    else
        return true
    end
end

------------------------------------

local window = graphic.createWindow(screen, posX, posY, rx - (posX - 1), ry - (posY - 1))

local function draw()
    local currentTimezone = 3
    if fs.exists(passwordPath) then
        local file = fs.open(passwordPath, "rb")
        local data = file.readAll()
        file.close()
        if data then
            currentTimezone = data
        end
    end

    window:clear(colors.black)
    window:set(1, 1, colors.lightGray, fs.exists(passwordPath) and colors.lime or colors.red, "lock: " .. tostring(fs.exists(passwordPath)))
    window:set(1, 2, colors.lightGray, colors.white, "remove password")
    window:set(1, 3, colors.lightGray, colors.white, "set    password")
end
draw()

------------------------------------

return function(eventData)
    local windowEventData = window:uploadEvent(eventData)
    if windowEventData[1] == "touch" then
        if windowEventData[4] == 2 and windowEventData[3] >= 1 and windowEventData[3] <= 15 then
            if fs.exists(passwordPath) then
                if checkPassword() then
                    fs.remove(passwordPath)
                end
            else
                gui_warn(screen, nil, nil, "password is not setted")
            end
            draw()
        elseif windowEventData[4] == 3 and windowEventData[3] >= 1 and windowEventData[3] <= 15 then
            if checkPassword() then
                local password1 = gui_input(screen, nil, nil, "enter password", true)
                if password1 then
                    local password2 = gui_input(screen, nil, nil, "comfurm password", true)
                    if password2 then
                        if password1 == password2 then
                            local file = fs.open(passwordPath, "wb")
                            file.write(sha256(password1))
                            file.close()
                        else
                            gui_warn(screen, nil, nil, "password is not equals")
                        end
                    end
                end
            end
            draw()
        end
    end
end