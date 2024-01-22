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
                require("thread").createBackground(function ()
                    local sound = require("sound")
                    sound.beep(200, 0.1, true)
                    sound.beep(200, 0.1, true)
                    sound.beep(200, 1)
                end):resume()
            end
            oldLowPower = lowPower
        end
    end
end, math.huge)