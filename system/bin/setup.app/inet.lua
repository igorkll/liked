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

registerButton = accountLayout:createButton(((rx / 2) - 8) - 10, ry - 2, 16, 1, uix.colors.lightBlue, uix.colors.white, "register", true)
loginButton = accountLayout:createButton(((rx / 2) - 8) + 10, ry - 2, 16, 1, uix.colors.lightBlue, uix.colors.white, "login", true)

accountDelButton = accountLayout:createButton(((rx / 2) - 8) - 10, ry - 2, 16, 1, uix.colors.lightBlue, uix.colors.white, "delete account", true)
unloginButton = accountLayout:createButton(((rx / 2) - 8) + 10, ry - 2, 16, 1, uix.colors.lightBlue, uix.colors.white, "unlogin", true)

function accountLayout:onSelect()
    if not accountLayout.imagePath then
        accountLayout.locked = account.getLocked()
        accountLayout.login = account.getLogin()

        loginZone.read.setBuffer("")
        passwordZone.read.setBuffer("")
        passwordZone2.read.setBuffer("")
        loginZone.read.setLock(false)

        registerButton.dh = true
        loginButton.dh = true
        accountDelButton.dh = true
        unloginButton.dh = true

        if vtext1 then vtext1:destroy() end
        if vtext2 then vtext2:destroy() end
        if accountImage then accountImage:destroy() end

        if accountLayout.login then
            accountLayout.imagePath = uix.getSysImgPath("accountLogin")
            accountImage = accountLayout:createImage(((rx / 2) - (image.sizeX(accountLayout.imagePath) / 2)) + 1, 2, accountLayout.imagePath)
            accountImage.wallpaperMode = true

            loginZone.read.setBuffer(accountLayout.login)
            loginZone.read.setLock(true)

            accountDelButton.dh = false
            unloginButton.dh = false
        elseif accountLayout.locked then
            accountLayout.imagePath = uix.getSysImgPath("accountLock")
            accountImage = accountLayout:createImage(((rx / 2) - (image.sizeX(accountLayout.imagePath) / 2)) + 1, 2, accountLayout.imagePath)
            accountImage.wallpaperMode = true

            loginZone.read.setBuffer(accountLayout.locked)
            loginZone.read.setLock(true)

            vtext1 = accountLayout:createVText(rx / 2, ry - 11, uix.colors.orange, "your device is locked")
            vtext2 = accountLayout:createVText(rx / 2, ry - 10, uix.colors.orange, "enter account password to confirm that you are the owner")

            loginButton.dh = false
        else
            accountLayout.imagePath = uix.getSysImgPath("account")
            accountImage = accountLayout:createImage(((rx / 2) - (image.sizeX(accountLayout.imagePath) / 2)) + 1, 2, accountLayout.imagePath)
            accountImage.wallpaperMode = true

            registerButton.dh = false
            loginButton.dh = false
        end
    end
end

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

local function msg(msg, ok, err)
    if ok then
        gui.done(screen, nil, nil, msg)
    else
        gui.warn(screen, nil, nil, err or "unknown error")
    end

    ui:draw()
    return ok
end

local function refresh()
    accountLayout.imagePath = nil
    ui:select(accountLayout)
end

function registerButton:onClick()
    local pass = pass()
    if pass then
        if msg("you have successfully created an account!\nnow you can log in to it", account.register(loginZone.read.getBuffer(), pass)) then
            refresh()
        end
    end
end

function loginButton:onClick()
    local pass = pass()
    if pass then
        if msg("you have successfully logged in to your account", account.login(loginZone.read.getBuffer(), pass)) then
            refresh()
        end
    end
end

function accountDelButton:onClick()
    local pass = pass()
    if pass and gui.yesno(screen, nil, nil, "do you really want to delete your account :(") and gui.pleaseType(screen, "ACDEL", "delete account") then
        if msg("you have successfully deleted your account", account.unregister(loginZone.read.getBuffer(), pass)) then
            refresh()
        end
    end
end

function unloginButton:onClick()
    local pass = pass()
    if pass then
        if msg("you have successfully logged out of your account", account.unlogin(pass)) then
            refresh()
        end
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