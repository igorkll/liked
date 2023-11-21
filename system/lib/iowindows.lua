local gui = require("gui")
local iowindows = {}

function iowindows.loadfile(screen)
    return gui_filepicker(screen)
end

iowindows.unloadable = true
return iowindows