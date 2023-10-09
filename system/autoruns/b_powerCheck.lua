local event = require("event")
local system = require("system")
local registry = require("registry")
local computer = require("computer")

local oldLowPower
event.timer(1, function ()
    local lowPower = system.getCharge() <= 30
    if lowPower ~= oldLowPower then
        if lowPower and registry.lowPowerSound then
            computer.beep(200)
            computer.beep(200)
            computer.beep(200, 1)
        end
        oldLowPower = lowPower
    end
end, math.huge)