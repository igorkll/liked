local gui = require("gui")
local computer = require("computer")

local screen = ...

gui.actionContext(screen, 8, 8, {
    clear = true,
    redrawCallback = function() end, --the context menu may ask you to redraw everything that is under it
    {
        title = "title",
        active = true,
        callback = function()
            computer.beep(2000, 1)
            return true --return from context
        end
    },
    true, --break line
    {
        title = "menu",
        active = true,
        menu = {
            {
                title = "1",
                active = true,
                callback = function()
                    computer.beep(500, 0.1)
                end
            },
            {
                title = "2",
                active = true,
                callback = function()
                    computer.beep(1000, 0.1)
                end
            },
            {
                title = "3",
                active = true,
                callback = function()
                    computer.beep(1500, 0.1)
                end
            }
        }
    }
})