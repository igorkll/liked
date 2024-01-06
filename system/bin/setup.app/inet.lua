local uix = require("uix")
local gobjs = require("gobjs")
local fs = require("filesystem")
local graphic = require("graphic")
local colorlib = require("colors")
local computer = require("computer")
local registry = require("registry")
local internet = require("internet")

local screen = ...
local ui = uix.manager(screen)
local rx, ry = ui:size()

--------------------------------

local inetLayout = ui:simpleCreate(uix.colors.cyan, uix.styles[2])
inetLayout:createLabel(2, 2, inetLayout.window.sizeX - 2, 1, uix.colors.cyan, uix.colors.white, "there is no internet connection")

--local recheckButton = inetLayout:createButton()

--------------------------------

local accauntLayout = ui:simpleCreate(uix.colors.cyan, uix.styles[2])

--------------------------------

if internet.check() then
    ui:select(accauntLayout)
else
    ui:select(inetLayout)
end
ui:loop()