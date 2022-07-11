local graphic = require("graphic")
local computer = require("computer")
local event = require("event")
local calls = require("calls")
local unicode = require("unicode")
local programs = require("programs")
local gui_container = require("gui_container")
local fs = require("filesystem")
local paths = require("paths")

local colors = gui_container.colors

------------------------------------

local screen = ...
local rx, ry = graphic.findGpu(screen).getResolution()

local statusWindow = graphic.classWindow:new(screen, 1, 1, rx, 1)
local window = graphic.classWindow:new(screen, 1, 2, rx, ry)

local wallpaperPath = "/data/wallpaper.t2p"
local userRoot = "/data/userdata"
local userPath = userRoot
fs.makeDirectory(userRoot)

------------------------------------

local selectStr = 0
local selectedIcon = 1

local function drawStatus()
    local hours, minutes, seconds = calls.call("getRealTime", 3)
    hours = tostring(hours)
    minutes = tostring(minutes)
    if #hours == 1 then hours = "0" .. hours end
    if #minutes == 1 then minutes = "0" .. minutes end
    local str = hours .. ":" .. minutes

    statusWindow:fill(1, 1, rx, 1, colors.gray, 0, " ")
    statusWindow:set(window.sizeX - unicode.len(str), 1, colors.gray, colors.white, str)
    statusWindow:set(1, 1, colors.lightGray, colors.white, " OS ")
end
local function draw()
    drawStatus()
    window:clear(colors.lightBlue)

    if fs.exists(wallpaperPath) then
        local sx, sy = calls.call("gui_readimagesize", wallpaperPath)
        local ix, iy = ((window.sizeX / 2) - (sx / 2)) + 1, ((window.sizeY / 2) - (sy / 2)) + 1
        calls.call("gui_drawimage", screen, wallpaperPath, ix, iy)
    end

    for i, v in ipairs(fs.list(userPath)) do
        local path = paths.concat(userPath, v)
        local exp = paths.extension(path)
        local icon
        if exp then
            icon = paths.concat("/system/icons", exp .. ".t2p")
            if not fs.exists(icon) then
                icon = nil
            end
        end

        local iconValue = i

        if iconValue > 0 then
            local pad = 16
            local padY = pad // 2
            local posX = (((iconValue * pad) - 1) % rx) + 1
            local posY = (((iconValue * pad) // rx) + 1) * padY
            local size = 10
            local sizeY = size // 2

            local drawPointX = posX - (size // 2)
            local drawPointY = posY - (sizeY // 2)
            if selectedIcon == i then
                window:fill(drawPointX - 1, drawPointY - 1, size + 2, sizeY + 1, colors.blue, 0, " ")
            end
            window:set(posX - (unicode.len(v) // 2), posY + sizeY - 2, colors.lightBlue, colors.white, v)
        end
    end
end
draw()

------------------------------------

local statusTimer
local function startStatusTimer()
    statusTimer = event.timer(10, function()
        drawStatus()
    end, math.huge)
end
local function stopStatusTimer()
    event.cancel(statusTimer)
end
startStatusTimer()

------------------------------------

local function execute(name, ...)
    stopStatusTimer()
    local code, err = programs.load(name)
    local ok = true
    if code then
        local ok2, err2 = xpcall(code, debug.traceback, screen, ...)
        if not ok2 then
            err = err2
            ok = false
        end
    else
        ok = false
    end
    startStatusTimer()
    if not ok then
        draw()
        calls.call("gui_warn", screen, 1, 2, err or "unknown error")
    end
end

while true do
    local eventData = {event.pull()}
    local windowEventData = window:uploadEvent(eventData)
    local statusWindowEventData = statusWindow:uploadEvent(eventData)
    if statusWindowEventData[1] == "touch" then
        if statusWindowEventData[4] == 1 and statusWindowEventData[3] >= 1 and statusWindowEventData[3] <= 4 then
            local str, num = calls.call("gui_context", screen, 2, 2,
            {"  about", "  settings", "  paint(temp)", "------------------", "  shutdown", "  reboot"},
            {true, true, true, false, true, true})
            if num == 1 then
                execute("about")
            elseif num == 2 then
                execute("settings")
            elseif num == 3 then
                execute("paint", "/data/temp.t2p")
            elseif num == 5 then
                computer.shutdown()
            elseif num == 6 then
                computer.shutdown(true)
            end
            draw()
        end
    end

    if eventData[1] == "redrawDesktop" then
        draw()
    end
end