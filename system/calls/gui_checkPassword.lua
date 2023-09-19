local registry = require("registry")

local screen, cx, cy, disableStartSound = ...

if registry.password then
    local clear = saveZone(screen)
    local password = gui_input(screen, cx, cy, "enter password", true, nil, nil, disableStartSound)
    clear()

    if password then
        if sha256(password .. (registry.passwordSalt or "")) == registry.password then
            return true
        else
            local clear = saveZone(screen)
            gui_warn(screen, cx, cy, "invalid password")
            clear()
        end
    else
        return false --false означает что пользователь отказался от ввода пароля
    end
else
    return true
end