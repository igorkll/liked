local uix = require("uix")
local event = require("event")
local lastinfo = require("lastinfo")
local image = require("image")
local fs = require("filesystem")
local paths = require("paths")
local graphic = require("graphic")
local thread = require("thread")
local computer = require("computer")
local gui = require("gui")

local screen = ...
local manager = uix.manager(screen)
local rx, ry = manager:zoneSize()
local layout = manager:create("Slide Show")


local path = "/data/userdata/images"
local interval = 4

layout:createText(2, ry - 5, nil, "Press 'Enter' key to exit from viewer")
layout:createText(2, 2, nil, "likeOS water-mark: ")
local startButton = layout:createButton(2, ry - 3, rx - 2, 3, nil, nil, "Start Slide Show", true)
local waterMark = layout:createSwitch(21, 2, true)

function startButton:onClick()
    layout.active = false
    layout:stop()

    local first = true

    thread.create(function ()
        while true do
            for _, name in ipairs(fs.list(path)) do
                local fullpath = paths.concat(path, name)
                if paths.extension(name) == "t2p" then
                    local sx, sy = image.size(fullpath)
                    graphic.setResolution(screen, sx, sy)

                    if first then
                        graphic.createWindow(screen, 1, 1, sx, sy):fill(1, 1, sx, sy, 0, 0, " ")
                        graphic.forceUpdate(screen)
                        first = false
                    end

                    local startTime = computer.uptime()
                    image.draw(screen, fullpath, 1, 1)
                    if waterMark.state then
                        gui.drawtext(screen, 2, sy - 3, 0xffffff, "Operating System     : likeOS & liked")
                        gui.drawtext(screen, 2, sy - 2, 0xffffff, "Application          : slideShow")
                        gui.drawtext(screen, 2, sy - 1, 0xffffff, "Developer In Discord : smlogic")
                    end
                    graphic.forceUpdate(screen)
                    local drawTime = computer.uptime() - startTime
                    
                    local waitTime = interval - drawTime
                    if waitTime < 0 then waitTime = 0 end
                    os.sleep(waitTime)
                end
            end
            os.sleep(0.1)
        end
    end):resume()
end

function manager:onEvent(eventData)
    if eventData[1] == "key_down" and table.exists(lastinfo.keyboards[screen], eventData[2]) and eventData[3] == 13 and eventData[4] == 28 then
        os.exit()
    end
end

manager:loop()