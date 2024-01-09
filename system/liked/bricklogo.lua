local component = component or require("component")
local computer = computer or require("computer")
local unicode = unicode or require("unicode")

computer.beep("...-")

local gpu = component.proxy(component.list("gpu")() or "")
if gpu then
    for address in component.list("screen") do
        gpu.bind(address)
        if not pcall(gpu.setResolution, 80, 25) then
            pcall(gpu.setResolution, 50, 16)
        end

        -- base
        local w, h = gpu.getResolution()
        local wC, hC = w / 2, h / 2

        local triangle = {
            "     ◢█◣",
            "    ◢███◣",
            "   ◢█████◣",
            "  ◢███████◣",
            " ◢█████████◣",
            "◢███████████◣",
        }

        local warn = {
            "█",
            "█",
            "█",
            "",
            "▀",
        }

        -- palette
        local palette = false
        if gpu.getDepth() > 1 then
            palette = true
            gpu.setPaletteColor(0, 0x000000)
            gpu.setPaletteColor(1, 0xff0000)
            gpu.setPaletteColor(2, 0xffffff)
        end

        -- draw
        local trianglePosX = math.ceil(wC - 6)
        local trianglePosY = math.ceil(hC - 7)


        gpu.setBackground(0, palette)
        gpu.setForeground(1, palette)
        gpu.fill(1, 1, w, h, " ")
        for str = 1, #triangle do
            gpu.set(trianglePosX, str + trianglePosY, triangle[str])
        end

        if palette then
            gpu.setBackground(1, true)
            gpu.setForeground(2, true)
        else
            gpu.setBackground(0xffffff)
            gpu.setForeground(0x000000)
        end
        for str = 1, #warn do 
            gpu.set(trianglePosX + 6, trianglePosY + str + 1, warn[str])
        end

        gpu.setBackground(0, palette)
        gpu.setForeground(2, palette)

        local function centerPrint(y, text)
            gpu.set(math.floor(wC - (unicode.len(text) / 2)) + 1, y, text)
        end

        centerPrint(hC + 3, "The system was remotely destroyed")
        centerPrint(hC + 4, "Press power button to shutdown")
    end
end

while true do
    computer.pullSignal()
end