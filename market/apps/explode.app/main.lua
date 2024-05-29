local screen = ...
local graphic = require("graphic")
local computer = require("computer")
local component = require("component")
local gui_container = require("gui_container")
local gui = require("gui")
local colors = gui_container.colors
local advLabeling = require("advLabeling")
local thread = require("thread")
local rx, ry = graphic.getResolution(screen)
local orx, ory = rx, ry

local window = graphic.createWindow(screen, 1, 1, rx, ry)

----------------------------

_G.bgTimeTbls = _G.bgTimeTbls or {}

local function bgTime(destruct, time, tbl)
    _G.bgTimeTbls[destruct.address] = tbl

    for i = 0, 5 do
        if destruct.getOutput(i) ~= 0 then
            destruct.setOutput(i, 0)
        end
    end

    local crs_time
    local startTime = computer.uptime()
    while true do
        crs_time = time - (computer.uptime() - startTime)
        if crs_time < 0 then crs_time = 0 end
        local str = tostring(math.round(crs_time))
        tbl.str = str

        if crs_time and crs_time <= 0 then
            for i = 0, 5 do
                if destruct.getOutput(i) ~= 15 then
                    destruct.setOutput(i, 15)
                end
            end
            _G.bgTimeTbls[destruct.address].str = nil
            _G.bgTimeTbls[destruct.address] = nil
            break
        end

        os.sleep(0.1)
    end
end

local function timer(destruct, getTimeTbl)
    rx, ry = 8, 4
    graphic.setResolution(screen, rx, ry)

    while true do
        local str = ""
        if destruct then
            local ok, time = pcall(destruct.time)
            if not ok then break end
            str = tostring(math.round(time))
        else
            if not getTimeTbl.str then break end
            str = getTimeTbl.str
        end

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

local destructUuid = gui_selectcomponent(screen, nil, nil, {"self_destruct", "server_destruct", "redstone"}, true)
if destructUuid then
    local destruct = component.proxy(destructUuid)

    local isRed = destruct.type == "redstone"
    if (not isRed and destruct.time() > 0) or (isRed and _G.bgTimeTbls[destruct.address]) then --если таймер уже запушен, то просто отображаем его
        if _G.bgTimeTbls[destruct.address] then
            timer(nil, _G.bgTimeTbls[destruct.address])
        else
            timer(destruct)
        end
    else
        window:fill(1, 1, rx, ry, colors.black, 0, " ")

        local num
        while true do
            num = gui.input(screen, nil, nil, "timer")
            if not num then
                return
            end
            num = tonumber(num)
            if num then
                if num < 0 or (num > 100000 and not isRed) then
                    gui.warn(screen, nil, nil, "the number must be in the range 0/" .. (isRed and "huge" or "100000"))
                else
                    break
                end
            else
                gui.warn(screen, nil, nil, "enter a number")
            end
        end
        
        local name = destruct.type .. ":" .. destructUuid:sub(1, 4)
        local label = advLabeling.getLabel(destructUuid)
        if label then name = name .. ":" .. label end

        if gui.yesno(screen, nil, nil, "do you really want to explode " .. name .. "? the timer cannot be stopped!") then
            if not isRed then
                destruct.start(num)
                timer(destruct)
            else
                local tbl = {str = tostring(math.round(num))}
                thread.createBackground(bgTime, destruct, num, tbl):resume()
                os.sleep(0.1)
                timer(nil, tbl)
            end
        end
    end
end