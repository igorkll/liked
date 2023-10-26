local graphic = require("graphic")
local event = require("event")
local gui_container = require("gui_container")
local package = require("package")
local syntax = require("syntax")
local liked = require("liked")
local thread = require("thread")

local colors = gui_container.colors

--------------------------------

local screen = ...

local sizeX, sizeY = graphic.getResolution(screen)
local window = graphic.createWindow(screen, 1, 1, sizeX, sizeY, true)
local reader = window:read(1, sizeY, sizeX, colors.gray, colors.white, "lua: ", nil, nil, nil, "lua")

local upTh, upRedraw, upCallbacks = liked.drawFullUpBarTask(screen, "Lua")
local baseTh = thread.current()
upCallbacks.exit = function ()
    baseTh:kill()
end

do
    window:clear(colors.black)
    upRedraw()
    reader.redraw()
end

local function lprint(color, ...)
    local tbl = {...}
    for i = 1, #tbl do
        tbl[i] = tostring(tbl[i])
    end
    window:copy(1, 3, sizeX, sizeY - 3, 0, -1)
    window:fill(1, sizeY - 1, sizeX, 1, colors.black, 0, " ")
    window:set(1, sizeY - 1, colors.black, color, table.concat(tbl, "    "))
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
        reader.redraw()
        lprint(colors.green, "LUA>")
        syntax.draw(6, sizeY - 1, syntax.parse(readerData), graphic.findGpu(screen))
        
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
end