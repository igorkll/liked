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
local storage = require("storage")
local iowindows = require("iowindows")

local config = storage.getConf({
    interval = 4,
    water = true
})

local screen = ...
local manager = uix.manager(screen)
local rx, ry = manager:zoneSize()
local layout = manager:create("Slide Show")

layout:createImage(rx - 29, 1, "hue.t2p", true, true)

layout:createText(2, ry - 5, nil, "Press 'Enter' key to exit from viewer")
layout:createText(2, 2, nil, "likeOS water-mark: ")
local startButton = layout:createButton(2, ry - 3, rx - 2, 3, nil, nil, "Start Slide Show", true)
local waterMark = layout:createSwitch(21, 2, config.water)
local folderText = layout:createText(2, 4)

local invervalText = layout:createText(rx - 5, ry - 7)

local function updateText()
    folderText.text = "images folder: " .. (config.folder and paths.name(config.folder) or "not selected")
    folderText:draw()
end

local function updateSeekText()
    invervalText.text = tostring(math.round(config.interval)) .. "S  "
    invervalText:draw()
end

updateText()
updateSeekText()

local unselect = layout:createButton(2, 5, 10, 1, nil, nil, "unselect")
local selectfolder = layout:createButton(13, 5, 8, 1, nil, nil, "select", true)
layout:createText(2, ry - 7, nil, "inverval: ")
local seek = layout:createSeek(12, ry - 7, rx - 18, nil, nil, nil, math.map(config.interval, 1, 60, 0, 1))

function seek:onSeek(value)
    config.interval = math.mapRound(value, 0, 1, 1, 60)
    updateSeekText()
end


function unselect:onClick()
    config.folder = nil
    updateText()
end

function selectfolder:onClick()
    local folder = iowindows.selectfolder(screen)
    if folder then
        config.folder = folder
        updateText()
    end
    layout:draw()
end

function waterMark:onSwitch()
    config.water = self.state
end

function startButton:onClick()
    local path = config.folder
    
    if path then
        layout.active = false
        layout:stop()

        local first = true

        thread.create(function ()
            while true do
                for _, name in ipairs(fs.list(path)) do
                    local fullpath = paths.concat(path, name)
                    local exp = paths.extension(name)
                    if exp == "t2p" then
                        local sx, sy = image.size(fullpath)
                        local cropped
                        if not graphic.isValidResolution(screen, sx, sy) or not pcall(graphic.setResolution, screen, sx, sy) then
                            sx, sy = graphic.maxResolution(screen)
                            cropped = true
                        end

                        if first then
                            graphic.fill(screen, 1, 1, sx, sy, 0, 0, " ")
                            graphic.forceUpdate(screen)
                            first = false
                        end

                        if graphic.getDepth(screen) == 4 then
                            if not image.applyPalette(screen, fullpath) then
                                palette.blackWhite(screen, true)
                            end
                        end
                        local startTime = computer.uptime()
                        if cropped then
                            local ix, iy = image.size(fullpath)
                            image.draw(screen, fullpath, 1 - (ix / 2), 1 - (iy / 2), nil, true)
                        else
                            image.draw(screen, fullpath, 1, 1, nil, true)
                        end
                        if waterMark.state then
                            gui.drawtext(screen, 2, sy - 3, 0xffffff, "Operating System     : likeOS & liked")
                            gui.drawtext(screen, 2, sy - 2, 0xffffff, "Application          : slideshow")
                            gui.drawtext(screen, 2, sy - 1, 0xffffff, "Developer In Discord : smlogic")
                        end
                        graphic.forceUpdate(screen)

                        local drawTime = computer.uptime() - startTime
                        local waitTime = config.interval - drawTime
                        if waitTime < 0.1 then waitTime = 0.1 end
                        os.sleep(waitTime)
                    end
                end
                os.sleep(0.1)
            end
        end):resume()
    else
        gui.warn(screen, nil, nil, "first, select the folder with the pictures")
        layout:draw()
    end
end

function manager:onEvent(eventData)
    if eventData[1] == "key_down" and table.exists(lastinfo.keyboards[screen], eventData[2]) and eventData[3] == 13 and eventData[4] == 28 then
        os.exit()
    end
end

manager:loop()