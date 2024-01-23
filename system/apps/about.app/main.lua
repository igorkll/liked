local computer = require("computer")
local system = require("system")
local uix = require("uix")
local fs = require("filesystem")
local thread = require("thread")
local liked = require("liked")
local bitMapFonts = require("bitMapFonts")
local font = bitMapFonts.load()

local screen = ...
local ui = uix.manager(screen)
local rx, ry = ui:zoneSize()

---------------------------------

local cpuLevel, isApu = system.getCpuLevel()
local hddTotalSpace = fs.get("/").spaceTotal()
local hddUsedSpace = fs.get("/").spaceUsed()


local layout = ui:create("About", uix.colors.white)
layout:createText(2, 2, uix.colors.black, "Operating System : " .. tostring(_OSVERSION) .. " / " .. tostring(_COREVERSION))
layout:createText(2, 3, uix.colors.black, "Computer Address : " .. computer.address())
layout:createText(2, 4, uix.colors.black, "Boot Disk        : " .. fs.bootaddress)
layout:createText(2, 5, uix.colors.black, "Device Type      : " .. system.getDeviceType())
layout:createText(2, 6, uix.colors.black, "Processor        : tier-" .. tostring(cpuLevel) .. (isApu and " (APU)" or ""))
layout:createText(2, 7, uix.colors.black, "Computer Score   : ")

local linePoses = 22
local textSizes = 10

layout:createText(2, ry - 1, uix.colors.black, "CPU load level")
local cpuBar = layout:createProgress(linePoses, ry - 1, rx - linePoses - textSizes, uix.colors.red, uix.colors.lightGray, 0)

layout:createText(2, ry - 2, uix.colors.black, "amount of used RAM")
local ramBar = layout:createProgress(linePoses, ry - 2, rx - linePoses - textSizes, uix.colors.green, uix.colors.lightGray, 0)

layout:createText(2, ry - 3, uix.colors.black, "amount of used ROM")
local romBar = layout:createProgress(linePoses, ry - 3, rx - linePoses - textSizes, uix.colors.purple, uix.colors.lightGray, 0)

layout:createText(2, ry - 4, uix.colors.black, "energy reserve")
local energyBar = layout:createProgress(linePoses, ry - 4, rx - linePoses - textSizes, uix.colors.orange, uix.colors.lightGray, 0)

local function updateBars()
    local totalMemory = computer.totalMemory()
    local freeMemory = computer.freeMemory()

    local totalEnergy = computer.energy()
    local maxEnergy = computer.maxEnergy()
    
    local hddUsedValue = hddUsedSpace / hddTotalSpace
    local ramUsedValue = 1 - (freeMemory / totalMemory)
    local energyVal = totalEnergy / maxEnergy


    ramBar.value = ramUsedValue
    romBar.value = hddUsedValue
    energyBar.value = energyVal
    cpuBar.value = 0
end

function layout:onRedraw()
    updateBars()

    local px, py = layout.window:toRealPos(21, 7)
    local score = liked.getComputerScore()
    font:draw(screen, px, py, tostring(score), 1, liked.getScoreColor(score))
end

thread.create(function ()
    while true do
        updateBars()
        cpuBar.value = system.getCpuLoadLevel()

        ramBar:draw()
        romBar:draw()
        energyBar:draw()
        cpuBar:draw()
    end
end):resume()

---------------------------------

ui:loop()