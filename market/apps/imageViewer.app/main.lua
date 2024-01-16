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
local palette = require("palette")

local config = storage.getConf({
    water = true
})

local screen = ...
local manager = uix.manager(screen)
local rx, ry = manager:zoneSize()
local layout = manager:create("Image Viewer")

layout:createImage(rx - 29, 1, "logo.t2p")

layout:createText(2, ry - 5, nil, "Press 'Enter' key to exit from viewer")
layout:createText(2, 2, nil, "likeOS water-mark: ")
local startButton = layout:createButton(2, ry - 3, rx - 2, 3, nil, nil, "Start View", true)
local waterMark = layout:createSwitch(21, 2, config.water)
local folderText = layout:createText(2, 4)

local function updateText()
    folderText.text = "image path: " .. (config.imagepath and paths.hideExtension(paths.name(config.imagepath)) or "not selected")
    folderText:draw()
end

updateText()

local unselect = layout:createButton(2, 5, 10, 1, nil, nil, "unselect")
local selectfolder = layout:createButton(13, 5, 8, 1, nil, nil, "select", true)

function unselect:onClick()
    config.imagepath = nil
    updateText()
end

function selectfolder:onClick()
    local folder = iowindows.selectfile(screen, "t2p")
    if folder then
        config.imagepath = folder
        updateText()
    end
    layout:draw()
end

function waterMark:onSwitch()
    config.water = self.state
end

function startButton:onClick()
    local path = config.imagepath
    
    if path then
        layout.active = false
        layout:stop()



        local sx, sy = image.size(path, screen)
        local cropped
        if not graphic.isValidResolution(screen, sx, sy) or not pcall(graphic.setResolution, screen, sx, sy) then
            sx, sy = graphic.maxResolution(screen)
            cropped = true
        end
        if graphic.getDepth(screen) == 4 then
            image.applyPalette(screen, path)
        end
        graphic.clear(screen, uix.colors.black)
        local startTime = computer.uptime()
        if cropped then
            local ix, iy = image.size(path, screen)
            image.draw(screen, path, 1 - (ix / 2), 1 - (iy / 2))
        else
            image.draw(screen, path, 1, 1)
        end
        if waterMark.state then
            gui.drawtext(screen, 2, sy - 3, 0xffffff, "Operating System     : likeOS & liked")
            gui.drawtext(screen, 2, sy - 2, 0xffffff, "Application          : slideshow")
            gui.drawtext(screen, 2, sy - 1, 0xffffff, "Developer In Discord : smlogic")
        end
        graphic.forceUpdate(screen)
    else
        gui.warn(screen, nil, nil, "first you need to select an image")
        layout:draw()
    end
end

function manager:onEvent(eventData)
    if eventData[1] == "key_down" and table.exists(lastinfo.keyboards[screen], eventData[2]) and eventData[3] == 13 and eventData[4] == 28 then
        os.exit()
    end
end

manager:loop()