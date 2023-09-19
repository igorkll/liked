local screen = ...
local graphic = require("graphic")
local computer = require("computer")
local component = require("component")
local gui_container = require("gui_container")
local colors = gui_container.colors
local advLabeling = require("advLabeling")
local rx, ry = graphic.getResolution(screen)
local orx, ory = rx, ry

local window = graphic.createWindow(screen, 1, 1, rx, ry)

----------------------------

local function timer(destruct)
    gui_container.noScreenSaver[screen] = true
    rx, ry = 8, 4
    graphic.setResolution(screen, rx, ry)
    
    while true do
        local ok, time = pcall(destruct.time)
        if not ok then break end
        local str = tostring(math.round(time))

        local eventData = {computer.pullSignal(0.1)}
        local windowEventData = window:uploadEvent(eventData)

        window:fill(1, 1, rx, ry, colors.black, 0, " ")
        window:set(1, 1, colors.black, colors.red, "timeleft")
        window:set(5 - (#str // 2), 2, colors.black, colors.red, str)
        window:set(1, 4, colors.red, colors.black, "  EXIT  ")

        if windowEventData[1] == "touch" and windowEventData[4] == 4 then
            break
        end
    end

    graphic.setResolution(screen, orx, ory)
    gui_container.noScreenSaver[screen] = nil
end

----------------------------

window:fill(1, 1, rx, ry, colors.black, 0, " ")

while true do
    local out = gui_checkPassword(screen)
    if out == true then
        break
    elseif out == false then
        return
    end
end

local destructUuid = gui_selectcomponent(screen, nil, nil, {"self_destruct", "server_destruct"}, true)
if destructUuid then
    local destruct = component.proxy(destructUuid)

    if destruct.time() > 0 then --если таймер уже запушен, то просто отображаем его
        timer(destruct)
    else
        window:fill(1, 1, rx, ry, colors.black, 0, " ")

        local num
        while true do
            num = gui_input(screen, nil, nil, "timer")
            if not num then
                return
            end
            num = tonumber(num)
            if num then
                if num < 0 or num > 100000 then
                    gui_warn(screen, nil, nil, "the number must be in the range 0/100000")
                else
                    break
                end
            else
                gui_warn(screen, nil, nil, "enter a number")
            end
        end
        
        local name = destruct.type .. ":" .. destructUuid:sub(1, 4)
        local label = advLabeling.getLabel(destructUuid)
        if label then name = name .. ":" .. label end

        if gui_yesno(screen, nil, nil, "do you really want to explode " .. name .. "? the timer cannot be stopped!") then
            destruct.start(num)
            timer(destruct)
        end
    end
end