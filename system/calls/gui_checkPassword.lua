local registry = require("registry")
local sha256 = require("sha256").sha256

local screen, cx, cy = ...

if registry.password then
    local password = gui_input(screen, cx, cy, "enter password", true)

    if password then
        if sha256(password) == registry.password then
            return true
        else
            gui_warn(screen, cx, cy, "invalid password")
        end
    else
        return false --false означает что пользователь отказался от ввода пароля
    end
else
    return true
end