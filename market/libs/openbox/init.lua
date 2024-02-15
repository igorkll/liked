local vmx = require("vmx")
local system = require("system")
local graphic = require("graphic")
local paths = require("paths")
local fs = require("filesystem")
local component = require("component")
local event = require("event")
local lastinfo = require("lastinfo")
local screensaver = require("screensaver")
local liked = require("liked")

local boxPath = system.getResourcePath("box")
local eepromPath = system.getResourcePath("eepromImage")
local openbox = {}

function openbox.run(screen, program)
    local gpuAddress = screen and graphic.findGpuAddress(screen)

    local restoreGraphic
    if gpuAddress then
        restoreGraphic = vmx.hookGraphic(screen)
    end

    local result, result2, vm
    local tunnel = {}
    while true do
        vm = vmx.create(eepromPath, {boxPath, true, nil, "openos"})
        vm.env.os.program = paths.name(program)
        vm.env.os.tunnel = tunnel
        local progfs = vmx.fromVirtual(fs.dump(paths.path(program), false, nil, "program"))
        vm.bindComponent(progfs)
        vm.env.os.progfs = progfs

        if gpuAddress then
            vm.bindComponent(vmx.fromReal(gpuAddress))
        end
        
        if screen then
            vm.bindComponent(vmx.fromReal(screen))
            for _, keyboard in ipairs(lastinfo.keyboards[screen]) do
                vm.bindComponent(vmx.fromReal(keyboard))
            end
        end
        
        result2 = {xpcall(function()
            result = {vm.loop(function (time)
                local eventData = {event.pull(time)}
                if #eventData > 0 then
                    if screen then
                        local ctype
                        pcall(function ()
                            ctype = component.type(eventData[2])
                        end)
                        if ctype == "screen" then
                            if eventData[2] == screen then
                                return table.unpack(eventData)
                            end
                        elseif ctype == "keyboard" then
                            if table.exists(lastinfo.keyboards[screen], eventData[2]) then
                                return table.unpack(eventData)
                            end
                        end
                    end
                end
                return table.unpack(eventData)
            end)}
        end, debug.traceback)}

        if not result or (result[1] ~= true or result[2] ~= "reboot") then
            break
        end
    end
    
    if restoreGraphic then
        restoreGraphic()
    end

    assert(table.unpack(result2))
    assert(table.unpack(result))
    if tunnel.progError then
        return nil, tunnel.progError
    end
    return true
end

function openbox.runWithSplash(screen, program)
    return liked.bigAssert(screen, openbox.run(screen, program))
end

openbox.unloadable = true
return openbox