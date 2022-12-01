local graphic = require("graphic")
local event = require("event")
local gui_container = require("gui_container")
local brainfuck = require("brainfuck")

local colors = gui_container.colors

--------------------------------

local screen = ...

local sizeX, sizeY = graphic.getResolution(screen)
local window = graphic.createWindow(screen, 1, 1, sizeX, sizeY)

local programmReader = window:read(1, sizeY - 1, sizeX, colors.gray, colors.white, "programm: ", nil, nil, true)
local inputReader = window:read(1, sizeY, sizeX, colors.gray, colors.white, "input: ", nil, nil, true)

local isRunning = false
local interpreter
local outputLine = ""

local function update()
    local title = "Brainfuck"

    window:clear(colors.white)
    window:set(1, 1, colors.gray, colors.white, string.rep(" ", sizeX))
    window:set(math.floor(((sizeX / 2) - (#title / 2)) + 0.5), 1, colors.gray, colors.white, title)
    window:set(sizeX, 1, colors.red, colors.white, "X")

    window:set(1, sizeY - 3, isRunning and colors.red or colors.lime, colors.white, isRunning and "STOP " or "START")
    
    window:fill(1, sizeY - 2, sizeX, 1, colors.gray, 0, " ")
    window:set(1, sizeY - 2, colors.gray, colors.white, "output: " .. outputLine)
    
    programmReader.redraw()
    inputReader.redraw()
end

update()

--------------------------------

while true do
    local eventData = {event.pull(0.1)}
    local windowEventData = window:uploadEvent(eventData)
    programmReader.uploadEvent(eventData)
    inputReader.uploadEvent(eventData)

    if interpreter then
        for i = 1, 4096 do
            local next = interpreter.next()

            if next == "," then
                local input = inputReader.getBuffer()
                if #input > 0 then
                    interpreter.insert(input:byte(1))
                end
                inputReader.setBuffer(input:sub(2, #input))
            end

            local itype = interpreter.tick()
            if not itype then
                interpreter = nil
                isRunning = false
                break
            end

            if itype == "." then
                local output = interpreter.output()
                if output then
                    outputLine = outputLine .. string.char(output)
                end
            end
        end

        update()
    end

    if windowEventData[1] == "touch" then
        if windowEventData[3] == sizeX and windowEventData[4] == 1 then
            break
        elseif windowEventData[3] >= 1 and windowEventData[3] <= 5 and windowEventData[4] == sizeY - 3 then
            isRunning = not isRunning
            if isRunning then
                outputLine = ""
                interpreter = brainfuck.create(programmReader.getBuffer())
            else
                interpreter = nil
            end
            update()
        end
    end
end