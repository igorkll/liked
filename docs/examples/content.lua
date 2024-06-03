local gui = require("gui")
local computer = require("computer")

local screen = ...

gui.actionContext(screen, 8, 8, {
    {
        title = "test with exit",
        active = true,
        callback = function()
            computer.beep(2000, 1)
            return true --return from context
        end
    },
    {
        title = "test without exit",
        active = true,
        callback = function()
            computer.beep(1800, 1)
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
    },
    {
        title = "menu 2",
        active = true,
        menu = {
            {
                title = "1",
                active = true,
                callback = function()
                    computer.beep(100, 0.1)
                end
            },
            {
                title = "2",
                active = true,
                callback = function()
                    computer.beep(200, 0.1)
                end
            },
            {
                title = "3",
                active = true,
                callback = function()
                    computer.beep(300, 0.1)
                end
            }
        }
    }
})