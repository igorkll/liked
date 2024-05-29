local event = require("event")
local lastinfo = require("lastinfo")
local component = require("component")

event.listen("key_down", function(_, uuid, char, code)
    for screen in component.list("screen") do
        local ok
        for i, v in ipairs(lastinfo.keyboards[screen]) do
            if v == uuid then
                ok = true
            end
        end

        if ok then
            if char == 0 and code == 46 and not require("gui_container").noInterrupt[screen] then
                event.interruptFlag = screen
            end
        end
    end
end)