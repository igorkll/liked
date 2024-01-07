local uix = require("uix")
local gobjs = require("gobjs")
local fs = require("filesystem")
local graphic = require("graphic")
local colorlib = require("colors")
local computer = require("computer")
local registry = require("registry")
local internet = require("internet")
local image = require("image")
local gui = require("gui")

local screen = ...
local ui = uix.manager(screen)
local rx, ry = ui:size()

--------------------------------

local inetLayout = ui:simpleCreate(uix.colors.cyan, uix.styles[2])
inetLayout.imagePath = uix.getSysImgPath("noInternet")
inetLayout:createLabel(2, 2, inetLayout.window.sizeX - 2, 1, uix.colors.cyan, uix.colors.white, "there is no internet connection")
inetLayout:createImage((rx / 2) - (image.sizeX(inetLayout.imagePath) / 2), 4, inetLayout.imagePath)

local backButton = inetLayout:createButton(3, ry - 1, 8, 1, uix.colors.lightBlue, uix.colors.white, " ← back", true)
function backButton:onClick()
    os.exit()
end

local recheckButton = inetLayout:createButton(rx - 17, ry - 1, 16, 1, uix.colors.lightBlue, uix.colors.white, "recheck", true)
function recheckButton:onClick()
    if internet.check() then
        ui:select(accountLayout)
    else
        gui.warn(screen, nil, nil, "there is still no internet connection")
        ui:draw()
    end
end

local skipButton = inetLayout:createButton(rx - 17, ry - 3, 16, 1, uix.colors.lightBlue, uix.colors.white, "skip internet", true)
function skipButton:onClick()
    doSetup("end")
    os.exit()
end

--------------------------------

accountLayout = ui:simpleCreate(uix.colors.cyan, uix.styles[2])

function accountLayout:onSelect()
    if not accountLayout.imagePath then
        accountLayout.imagePath = uix.getSysImgPath("account")
        local accountImage = accountLayout:createImage(((rx / 2) - (image.sizeX(accountLayout.imagePath) / 2)) + 1, 2, accountLayout.imagePath)
        accountImage.wallpaperMode = true
    end
end

local backButton2 = accountLayout:createButton(3, ry - 1, 8, 1, uix.colors.lightBlue, uix.colors.white, " ← back", true)
function backButton2:onClick()
    os.exit()
end

--------------------------------

if internet.check() then
    ui:select(accountLayout)
else
    ui:select(inetLayout)
end
ui:loop()