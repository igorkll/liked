local init
do
    local data = component.proxy(component.list("eeprom")())

    do
        local screen = component.list("screen")()
        local gpu = component.list("gpu")()
        if gpu and screen then
            component.invoke(gpu, "bind", screen)
        end
    end

    _likedLoader = true
end
init()