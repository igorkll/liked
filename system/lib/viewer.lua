local uix = require("uix")
local fs = require("filesystem")
local gobjs = require("gobjs")
local viewer = {}

function viewer.license(screen, path)
    local ui = uix.manager(screen)
    local rx, ry = ui:size()
    local ret

    local licenseLayout = ui:simpleCreate(uix.colors.cyan, uix.styles[2])
    licenseLayout:createCustom(3, 2, gobjs.scrolltext, rx - 4, ry - 4, assert(fs.readFile(path)):gsub("\r", ""))

    local back1 = licenseLayout:createButton(3, ry - 1, 8, 1, uix.colors.lightBlue, uix.colors.white, " ← back", true)
    back1.alignment = "left"
    function back1:onClick()
        ret = false
        ui.exitFlag = true
    end

    local next2 = licenseLayout:createButton(rx - 17, ry - 1, 16, 1, uix.colors.lightBlue, uix.colors.white, "accept & next", true)
    function next2:onClick()
        ret = true
        ui.exitFlag = true
    end

    ui:loop()
    return ret
end

viewer.unloadable = true
return viewer