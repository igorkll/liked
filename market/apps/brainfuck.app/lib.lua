local brainfuck = {}

function brainfuck.create(code) --создаст интерпритатор с кодом
    local interpreter = {}
    interpreter.outputs = {}
    interpreter.inputs = {}
    interpreter.pos = 1
    interpreter.mem = {}
    interpreter.mempos = 0

    function interpreter.output() --вернет число из буфера вывода, если его там нет вернет nil
        local number = interpreter.outputs[1]
        table.remove(interpreter.outputs, 1)
        return number
    end

    function interpreter.insert(number) --положит чисто в буфер ввода
        table.insert(interpreter.inputs, number)
    end

    function interpreter.next() --вернет следуюшию инструкцию
        return code:sub(interpreter.pos, interpreter.pos)
    end

    function interpreter.tick() --исполнит инструкцию, вернет ту инструкцию что была выполнена, если вернет nil то программа закончилась
        local char = code:sub(interpreter.pos, interpreter.pos)
        if char == "" then char = nil end
        if char then
            if char == "." then
                table.insert(interpreter.outputs, interpreter.mem[interpreter.mempos] or 0)
            elseif char == "," then
                interpreter.mem[interpreter.mempos] = interpreter.inputs[1] or 0
                table.remove(interpreter.inputs, 1)
            elseif char == "+" then
                interpreter.mem[interpreter.mempos] = (interpreter.mem[interpreter.mempos] or 0) + 1
                if interpreter.mem[interpreter.mempos] > 255 then interpreter.mem[interpreter.mempos] = 0 end
            elseif char == "-" then
                interpreter.mem[interpreter.mempos] = (interpreter.mem[interpreter.mempos] or 0) - 1
                if interpreter.mem[interpreter.mempos] < 0 then interpreter.mem[interpreter.mempos] = 255 end
            elseif char == ">" then
                interpreter.mempos = interpreter.mempos + 1
            elseif char == "<" then
                interpreter.mempos = interpreter.mempos - 1
            elseif char == "[" then
                if (interpreter.mem[interpreter.mempos] or 0) == 0 then
                    local count = 0
                    while true do
                        local char = code:sub(interpreter.pos, interpreter.pos)
                        if char == "[" then
                            count = count + 1
                        elseif char == "]" then
                            count = count - 1
                        end
                        if count == 0 then
                            break
                        end
                        interpreter.pos = interpreter.pos + 1
                    end
                end
            elseif char == "]" then
                if (interpreter.mem[interpreter.mempos] or 0) ~= 0 then
                    local count = 0
                    while true do
                        local char = code:sub(interpreter.pos, interpreter.pos)
                        if char == "[" then
                            count = count + 1
                        elseif char == "]" then
                            count = count - 1
                        end
                        if count == 0 then
                            break
                        end
                        interpreter.pos = interpreter.pos - 1
                    end
                end
            end

            interpreter.pos = interpreter.pos + 1
        end
        return char
    end
    
    return interpreter
end

brainfuck.unloaded = true
return brainfuck