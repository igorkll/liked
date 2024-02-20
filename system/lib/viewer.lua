local uix = require("uix")
local fs = require("filesystem")
local viewer = {}

function viewer.license(path)
    local licenseLayout = ui:simpleCreate(uix.colors.cyan, uix.styles[2])
    licenseLayout:createCustom(3, 2, gobjs.scrolltext, rx - 4, ry - 4, assert(fs.readFile("/system/LICENSE")):gsub("\r", ""))

    back1 = licenseLayout:createButton(3, ry - 1, 8, 1, uix.colors.lightBlue, uix.colors.white, " ← back", true)
    back1.alignment = "left"
    function back1:onClick()
        ui:select(helloLayout)
    end

    next2 = licenseLayout:createButton(rx - 17, ry - 1, 16, 1, uix.colors.lightBlue, uix.colors.white, "accept & next", true)
    function next2:onClick()
        doSetup("inet")
        if registry.systemConfigured then
            os.exit()
        else
            ui:draw()
        end
    end

    function licenseLayout:onSelect()
        sysinit.initScreen(screen)
    end

    --------------------------------

    ui:loop()
end

viewer.unloadable = true
return viewer