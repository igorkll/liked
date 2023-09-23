local rx, ry = gpu.getResolution()
gpu.fill(1, 1, rx, ry, " ")

gpu.set(1, 1 , [[                                                  ]])
gpu.set(1, 2 , [[--------------------------------------------------]])
gpu.set(1, 3 , [[   █     █ █   █ ████             ██████ ██████   ]])
gpu.set(1, 4 , [[   █       █  █  █                █    █ █        ]])
gpu.set(1, 5 , [[   █     █ █ █   █                █    █ █        ]])
gpu.set(1, 6 , [[   █     █ ██    █                █    █ ██████   ]])
gpu.set(1, 7 , [[   █     █ ██    ████             █    █      █   ]])
gpu.set(1, 8 , [[   █     █ █ █   █                █    █      █   ]])
gpu.set(1, 9 , [[   █     █ █  █  █     installer  █    █      █   ]])
gpu.set(1, 10, [[   █████ █ █   █ ████             ██████ ██████   ]])
gpu.set(1, 11, [[--------------------------------------------------]])
gpu.set(1, 12, [[                                                  ]])
gpu.set(1, 13, [[                                                  ]])
gpu.set(1, 14, [[                                                  ]])
gpu.set(1, 15, [[--------------------------------------------------]])

if text then
    while text:sub(#text, #text) == "." do
        text = text:sub(1, #text - 1)
    end
    gpu.set(math.floor(((rx / 2) - (unicode.len(text) / 2)) + 0.5) + 1, 13, text or "")
end