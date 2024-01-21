local event = require("event")
local system = require("system")
local registry = require("registry")
local computer = require("computer")
local sysinit = require("sysinit")

local oldLowPower
event.timer(4, function ()
    if sysinit.full then
        local lowPower = system.getCharge() <= require("gui_container").criticalChargeLevel
        if lowPower ~= oldLowPower then
            if lowPower and registry.lowPowerSound then
                computer.beep(200)
                computer.beep(200)
                computer.beep(200, 1)
            end
            oldLowPower = lowPower
        end
    end
end, math.huge)