local graphic = require("graphic")
local event = require("event")
local gui_container = require("gui_container")
local package = require("package")
local syntaxHighlighting = require("syntaxHighlighting")

local colors = gui_container.colors

--------------------------------

local screen = ...

local sizeX, sizeY = graphic.getResolution(screen)
local window = graphic.createWindow(screen, 1, 1, sizeX, sizeY, true)
local reader = window:read(1, sizeY, sizeX, colors.gray, colors.white, "lua: ", nil, nil, nil, "lua")
local strs = {}

local function update()
    local title = "Lua"

    window:clear(colors.black)
    window:set(1, 1, colors.gray, colors.white, string.rep(" ", sizeX))
    window:set(math.floor(((sizeX / 2) - (#title / 2)) + 0.5), 1, colors.gray, colors.white, title)
    window:set(sizeX, 1, colors.red, colors.white, "X")

    for i, str in ipairs(strs) do
        local posY = sizeY - i
        if posY >= 2 then
            window:set(1, posY, colors.black, str[1], str[2])
            if str[3] then
                local x, y = window:toRealPos(1, posY)
                str[3](x + #str[2], y)
            end
        end
    end

    reader.redraw()
end

local function lprint(color, ...)
    local tbl = {...}
    for i = 1, #tbl do
        tbl[i] = tostring(tbl[i])
    end
    table.insert(strs, 1, {color, table.concat(tbl, "    ")})
    update()
end

--------------------------------

lprint(colors.white, _VERSION .. " Copyright (C) 1994-2022 Lua.org, PUC-Rio")
lprint(colors.yellow, "Enter a statement and hit enter to evaluate it.")
lprint(colors.yellow, "Prefix an expression with '=' to show its value.")
lprint(colors.yellow, "Press Ctrl+W to exit the interpreter.")

local env =  setmetatable({_G = _G, screen = screen, print = function (...)
    lprint(colors.white, ...)
end}, {__index = function (self, key)
    if _G[key] then
        return _G[key]
    elseif package.loaded[key] then
        return package.loaded[key]
    elseif package.cache[key] then
        return package.cache[key]
    end
end})

while true do
    local eventData = {event.pull()}
    local windowEventData = window:uploadEvent(eventData)
    local readerData = reader.uploadEvent(eventData)

    if readerData then
        if readerData == true then
            return
        end

        reader.setBuffer("")
        do
            local syntax = syntaxHighlighting.parse(readerData)
            table.insert(strs, 1, {colors.green, "LUA> ", function (x, y)
                syntaxHighlighting.draw(x, y, syntax, graphic.findGpu(screen))
            end})
            update()
        end
        
        if readerData:sub(1, 1) == "=" then
            readerData = "return " .. readerData:sub(2, #readerData)
        end

        env.gpu = graphic.findGpu(env.screen)
        local code, err = load(readerData, "=lua", "t", env)
        if code then
            local result = {pcall(code)}
            if result[1] then
                if #result > 1 then
                    lprint(colors.white, table.unpack(result, 2))
                end
            else
                lprint(colors.red, result[2] or "unknown error")
            end
        else
            lprint(colors.red, err or "unknown error")
        end
    end

    if windowEventData[1] == "touch" then
        if windowEventData[3] == sizeX and windowEventData[4] == 1 then
            break
        end
    end
end