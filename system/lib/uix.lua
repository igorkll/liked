local uix = {}

function uix:createBg(color)
    local obj = {}

    return obj
end

function uix.create(window, bgcolor)
    local guiobj = setmetatable({}, {__index = uix})
    guiobj.window = window
    guiobj.objs = {}

    return guiobj
end

return uix