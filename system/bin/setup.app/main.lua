local uix = require("uix")
local gobjs = require("gobjs")
local fs = require("filesystem")
local graphic = require("graphic")
local colorlib = require("colors")
local computer = require("computer")

local screen = ...
local ui = uix.manager(screen)
local rx, ry = ui:size()

-------------------------------- blincked hi

local blinckedHi = {}

function blinckedHi:draw()
    local line = self.y
    local gpu = graphic.findGpu(screen)
    if gpu then
        gpu.setBackground(uix.colors.cyan)
        gpu.setForeground(colorlib.red, true)
    end

    local function add(str)
        gpu.set(self.x, line, str)
        line = line + 1
    end

    add("███                 ███")
    add("███                 ███")
    add("███                    ")
    add("█████████           ███")
    add("██████████          ███")
    add("███      ██         ███")
    add("███      ███        ███")
    add("███      ███        ███")
    add("███      ███        ███")
    add("███      ███        ███")
    add("███      ███        ███")
    add("███      ███        ███")
end

--------------------------------

helloLayout = ui:simpleCreate(uix.colors.cyan, uix.styles[2])
helloLayout:createText(2, 1, uix.colors.white, "liked & likeOS")

hiObj = helloLayout:createCustom((rx / 2) - 11, (ry / 2) - 6, blinckedHi)

graphic.setPaletteColor(screen, colorlib.red, 0xffffff)
local function blink()
    hiObj:draw()

    local tick = 90
    helloLayout:timer(0.1, function ()
        local value = math.abs(math.sin(math.rad(tick)))
        graphic.setPaletteColor(screen, colorlib.red, colorlib.blend(value * 255, value * 255, value * 255))
        tick = (tick + 12) % 360

        if tick > 180 + 90 then
            return false
        end
    end, math.huge)
end
blink()
helloLayout:timer(4, blink, math.huge)

do
    local next1 = helloLayout:createButton((rx / 2) - 7, ry - 1, 16, 1, uix.colors.lightBlue, uix.colors.white, "next", true)
    function next1:onClick()
        ui:select(licenseLayout)
    end

    local reboot = helloLayout:createButton(rx - 16, 4, 16, 1, uix.colors.lightBlue, uix.colors.white, "reboot", true)
    function reboot:onClick()
        computer.shutdown(true)
    end

    local shutdown = helloLayout:createButton(rx - 16, 2, 16, 1, uix.colors.lightBlue, uix.colors.white, "shutdown", true)
    function shutdown:onClick()
        computer.shutdown()
    end
end

--------------------------------

licenseLayout = ui:simpleCreate(uix.colors.cyan, uix.styles[2])
licenseLayout:createCustom(3, 2, gobjs.scrolltext, rx - 4, ry - 4, assert(fs.readFile("/system/LICENSE")):gsub("\r", ""))

back1 = licenseLayout:createButton(3, ry - 1, 16, 1, uix.colors.lightBlue, uix.colors.white, " ← back", true)
back1.alignment = "left"
function back1:onClick()
    ui:select(helloLayout)
end

--------------------------------

ui:loop()