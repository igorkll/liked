local vmx = require("vmx")
local system = require("system")
local graphic = require("graphic")
local paths = require("paths")
local fs = require("filesystem")
local component = require("component")
local event = require("event")
local lastinfo = require("lastinfo")
local screensaver = require("screensaver")

local boxPath = system.getResourcePath("box")
local eepromPath = system.getResourcePath("eepromImage")
local openbox = {}

function openbox.run(screen, program)
    local gpuAddress = screen and graphic.findGpuAddress(screen)
    local vm = vmx.create(eepromPath, boxPath)
    fs.copy(program, paths.concat(boxPath, "autorun.lua"))
    
    local scrsvTurnOn
    if gpuAddress then
        scrsvTurnOn = screensaver.noScreensaver(screen)
        graphic.gpuPrivateList[gpuAddress] = true
        component.invoke(gpuAddress, "setActiveBuffer", 0)
        vm.bindComponent(vmx.fromReal(gpuAddress))
    end
    if screen then
        vm.bindComponent(vmx.fromReal(screen))
        for _, keyboard in ipairs(lastinfo.keyboards[screen]) do
            vm.bindComponent(vmx.fromReal(keyboard))
        end
    end
    
    local result
    local result2 = {xpcall(function()
        result = {vm.loop(function ()
            local eventData = {event.pull(0)}
            if #eventData > 0 then
                if not screen then
                    vm.pushSignal(table.unpack(eventData))
                else
                    local ctype
                    pcall(function ()
                        ctype = component.type(eventData[2])
                    end)
                    if ctype == "screen" then
                        if eventData[2] == screen then
                            vm.pushSignal(table.unpack(eventData))
                        end
                    elseif ctype == "keyboard" then
                        if table.exists(lastinfo.keyboards[screen], eventData[2]) then
                            vm.pushSignal(table.unpack(eventData))
                        end
                    else
                        vm.pushSignal(table.unpack(eventData))
                    end
                end
            end
        end)}
    end, debug.traceback)}

    graphic.gpuPrivateList[gpuAddress] = nil
    graphic.findGpu(gpuAddress)
    scrsvTurnOn()

    if not result2[1] then
        error(tostring(result2[2]), 2)
    end
    if result then
        return assert(table.unpack(result))
    end
end

openbox.unloadable = true
return openbox