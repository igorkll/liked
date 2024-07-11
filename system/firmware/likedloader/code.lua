local init
do
    _likedLoader = true
    local eeprom = component.proxy(component.list("eeprom")())
    

    do
        local screen = component.list("screen")()
        local gpu = component.list("gpu")()
        if gpu and screen then
            component.invoke(gpu, "bind", screen)
        end
    end

    if not init then
        error("liked loader: could not find a suitable OS to boot", 0)
    end

    component.invoke(computer.tmpAddress(), "makeDirectory", "bootloader") --blocks bootmanager startup
end
init()