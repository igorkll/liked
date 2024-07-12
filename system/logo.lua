drawed = drawed or {}

if not drawed[screen] then
    local rx, ry = bootloader.initScreen(gpu, screen, 80, 25)
    local sx, sy = 42, 10
    local x, y = ((rx / 2) - (sx / 2)) + 1, (ry / 2) - (sy / 2)
    local depth = gpu.getDepth()

    if depth ~= 1 then
        gpu.setPaletteColor(0, 0x000000)
        gpu.setPaletteColor(1, 0xff0000)
        gpu.setPaletteColor(2, 0xffffff)
    end

    gpu.setBackground(0x000000)
    gpu.fill(1, 1, rx, ry, " ")

    gpu.setBackground(0xff0000)
    gpu.fill(x, y, sx, sy, " ")

    if depth == 1 then
        gpu.setForeground(0x000000)
    else
        gpu.setForeground(0xffffff)
    end

    gpu.set(x, y + 0, "                                          ")
    gpu.set(x, y + 1, " █        ██   █      █   ██████   ███    ")
    gpu.set(x, y + 2, " █             █     █    █        █  ██  ")
    gpu.set(x, y + 3, " █        ██   █   ██     █        █    █ ")
    gpu.set(x, y + 4, " █        ██   █ ██       █        █    █ ")
    gpu.set(x, y + 5, " █        ██   ██         ██████   █    █ ")
    gpu.set(x, y + 6, " █        ██   █ ██       █        █    █ ")
    gpu.set(x, y + 7, " █        ██   █   ██     █        █    █ ")
    gpu.set(x, y + 8, " █        ██   █     █    █        █  ██  ")
    gpu.set(x, y + 9, " ██████   ██   █      █   ██████   ███    ")
    gpu.set(x, y +10, "                                          ")
else
    gpu.bind(screen, false)
    local rx, ry = gpu.getResolution()
    gpu.setBackground(0x000000)
    gpu.fill(1, ry - 1, rx, 1, " ")
end

if text then
    while text:sub(#text, #text) == "." do
        text = text:sub(1, #text - 1)
    end

    local rx, ry = gpu.getResolution()
    gpu.setBackground(0x000000)
    gpu.setForeground(0xffffff)
    gpu.set(math.floor(((rx / 2) - (unicode.len(text) / 2)) + 0.5) + 1, ry - 1, text or "")
end

drawed[screen] = true