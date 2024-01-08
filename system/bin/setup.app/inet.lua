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
local account = require("account")

local screen, _, window = ...
local ui = uix.manager(screen, window)
local rx, ry = ui:size()
local pwx, pwy
if window then
    rx, ry = window.sizeX, window.sizeY
    pwx, pwy = (window.sizeX / 2) - (gui.zoneX / 2), (window.sizeY / 2) - (gui.zoneY / 2)
end

--------------------------------

local inetLayout = ui:simpleCreate(uix.colors.cyan, uix.styles[2])
inetLayout.imagePath = uix.getSysImgPath("noInternet")
inetLayout:createLabel(2, 2, inetLayout.window.sizeX - 2, 1, uix.colors.cyan, uix.colors.white, "there is no internet connection")
inetLayout:createImage((rx / 2) - (image.sizeX(inetLayout.imagePath) / 2), 4, inetLayout.imagePath)

local recheckButton = inetLayout:createButton(rx - 17, ry - 1, 16, 1, uix.colors.lightBlue, uix.colors.white, "recheck", true)
function recheckButton:onClick()
    if internet.check() then
        ui:select(accountLayout)
    else
        gui.warn(screen, nil, nil, "there is still no internet connection")
        ui:draw()
    end
end

if not window then
    local backButton = inetLayout:createButton(3, ry - 1, 8, 1, uix.colors.lightBlue, uix.colors.white, " ← back", true)
    function backButton:onClick()
        os.exit()
    end

    local skipButton = inetLayout:createButton(rx - 17, ry - 3, 16, 1, uix.colors.lightBlue, uix.colors.white, "skip internet", true)
    function skipButton:onClick()
        doSetup("end")
        os.exit()
    end
end

--------------------------------

local loginInputPos = (rx / 2) - 19

accountLayout = ui:simpleCreate(uix.colors.cyan, uix.styles[2])
loginZone = accountLayout:createInput(loginInputPos, ry - 8, 40, uix.colors.white, uix.colors.black, false, nil, nil, nil,    "login   : ")
passwordZone = accountLayout:createInput(loginInputPos, ry - 6, 40, uix.colors.white, uix.colors.black, true, nil, nil, nil,  "password: ")
passwordZone2 = accountLayout:createInput(loginInputPos, ry - 4, 40, uix.colors.white, uix.colors.black, true, nil, nil, nil, "password: ")

function accountLayout:onSelect()
    if not accountLayout.imagePath then
        accountLayout.locked = account.getLocked()
        if accountLayout.locked then
            accountLayout.imagePath = uix.getSysImgPath("accountLock")
            local accountImage = accountLayout:createImage(((rx / 2) - (image.sizeX(accountLayout.imagePath) / 2)) + 1, 2, accountLayout.imagePath)
            accountImage.wallpaperMode = true

            loginZone.read.setBuffer(accountLayout.locked)
            loginZone.read.setLock(true)

            accountLayout:createVText(rx / 2, ry - 11, uix.colors.orange, "your device is locked")
            accountLayout:createVText(rx / 2, ry - 10, uix.colors.orange, "enter account password to confirm that you are the owner")
        else
            accountLayout.imagePath = uix.getSysImgPath("account")
            local accountImage = accountLayout:createImage(((rx / 2) - (image.sizeX(accountLayout.imagePath) / 2)) + 1, 2, accountLayout.imagePath)
            accountImage.wallpaperMode = true
        end
    end
end

registerButton = accountLayout:createButton(((rx / 2) - 8) - 10, ry - 2, 16, 1, uix.colors.lightBlue, uix.colors.white, "register", true)
loginButton = accountLayout:createButton(((rx / 2) - 8) + 10, ry - 2, 16, 1, uix.colors.lightBlue, uix.colors.white, "login", true)

local function pass()
    local pass1 = passwordZone.read.getBuffer()
    local pass2 = passwordZone2.read.getBuffer()
    if pass1 == pass2 then
        return pass1
    else
        gui.warn(screen, nil, nil, "passwords don't equals")
        ui:draw()
    end
end

local function msg(reg, ok, err)
    if ok then
        if reg then
            gui.done(screen, nil, nil, "you have successfully created an account!\nnow you can log in to it")
        else
            gui.done(screen, nil, nil, "you have successfully logged in to your account")
        end
    else
        gui.warn(screen, nil, nil, err or "unknown error")
    end

    ui:draw()
    return ok
end

function registerButton:onClick()
    local pass = pass()
    if pass then
        
    end
end

function loginButton:onClick()
    local pass = pass()
    if pass then
        msg(false, account.login(loginZone.read.getBuffer(), pass))
    end
end

if not window then
    local backButton2 = accountLayout:createButton(3, ry - 1, 8, 1, uix.colors.lightBlue, uix.colors.white, " ← back", true)
    function backButton2:onClick()
        os.exit()
    end
end

--------------------------------

if internet.check() then
    ui:select(accountLayout)
else
    ui:select(inetLayout)
end
ui:loop()