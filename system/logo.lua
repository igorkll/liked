drawed = drawed or {}

if not drawed[screen] then
    local logo =
[[
& _       _________ _        _______  ______  &
&( \      \__   __/| \    /\(  ____ \(  __  \ &
&| (         ) (   |  \  / /| (    \/| (  \  )&
&| |         | |   |  (_/ / | (__    | |   ) |&
&| |         | |   |   _ (  |  __)   | |   | |&
&| |         | |   |  ( \ \ | (      | |   ) |&
&| (____/\___) (___|  /  \ \| (____/\| (__/  )&
&(_______/\_______/|_/    \/(_______/(______/ &
]]

    local logoLines = {{true}}
    for i = 1, #logo do
        local char = logo:sub(i, i)
        if char == "\n" then
            table.insert(logoLines, {true})
        elseif char == "&" then
            if logoLines[#logoLines][1] == true then
                table.remove(logoLines[#logoLines], 1)
            else
                table.insert(logoLines[#logoLines], true)
            end
        elseif logoLines[#logoLines][#logoLines] ~= true then
            table.insert(logoLines[#logoLines], char)
        end
    end
    for i, v in ipairs(logoLines) do
        if v[1] == true then
            logoLines[i] = ""
        else
            table.remove(logoLines[i], #logoLines[i])
            logoLines[i] = table.concat(v)
        end
    end

    local rx, ry = bootloader.initScreen(gpu, screen, 80, 25)
    local sx, sy = 0, #logoLines
    for i, line in ipairs(logoLines) do
        if #line > sx then
            sx = #line
        end
    end
    sx = sx + 2
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

    for i = 1, #logoLines do
        gpu.set(x + 1, y + (i - 1), logoLines[i])
    end
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