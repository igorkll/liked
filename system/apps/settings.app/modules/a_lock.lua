local graphic = require("graphic")
local gui_container = require("gui_container")
local registry = require("registry")
local uuid = require("uuid")
local gui = require("gui")

local colors = gui_container.colors

------------------------------------

local screen, posX, posY = ...
local gpu = graphic.findGpu(screen)
local rx, ry = gpu.getResolution()

------------------------------------

local window = graphic.createWindow(screen, posX, posY, rx - (posX - 1), ry - (posY - 1))

local function draw()
    window:clear(colors.black)
    window:set(1, 1, colors.black, registry.password and colors.lime or colors.red, "lock: " .. tostring(not not registry.password))
    window:set(1, 3, colors.lightGray, colors.white, "remove password")
    window:set(1, 4, colors.lightGray, colors.white, "set    password")
end
draw()

------------------------------------

return function(eventData)
    local windowEventData = window:uploadEvent(eventData)
    if windowEventData[1] == "touch" then
        if windowEventData[4] == 3 and windowEventData[3] >= 1 and windowEventData[3] <= 15 then
            if registry.password then
                local ok, rawPassword = gui.checkPassword(screen)
                if ok then
                    registry.password = nil
                    registry.passwordSalt = nil
                    require("likedCryptoFs").decrypt(rawPassword)
                end
            else
                gui.warn(screen, nil, nil, "the password is not set")
            end
            draw()
        elseif windowEventData[4] == 4 and windowEventData[3] >= 1 and windowEventData[3] <= 15 then
            if gui.checkPassword(screen) then
                local password = gui.comfurmPassword(screen)
                if password then
                    local salt = uuid.next()
                    registry.password = require("sha256").sha256hex(password .. salt)
                    registry.passwordSalt = salt
                    require("likedCryptoFs").encrypt(password)
                end
            end
            draw()
        end
    end
end