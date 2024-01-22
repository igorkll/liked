local computer = require("computer")
local component = require("component")
local sound = {}

local iters = {}
local noiseChannelNums = {}
local function componentCoroutine(ctype)
    if iters[ctype] then
        local result = iters[ctype]()
        if result then
            return result
        end
    end

    iters[ctype] = component.list(ctype, true)
    if iters[ctype] then
        return (iters[ctype]())
    end
end

function sound.beep(freq, delay, blocked)
    freq = freq or 440
    delay = delay or 0.1

    local function wait()
        if blocked then
            os.sleep(delay + 0.1)
        end
    end

    local beep = componentCoroutine("beep")
    if beep then
        component.invoke(beep, "beep", {[freq] = delay})
        wait()
    else
        local noise = componentCoroutine("noise")
        if noise then
            local channel = noiseChannelNums[noise] or 1
            component.invoke(noise, "setMode", channel, 1)
            component.invoke(noise, "add", channel, freq, delay)
            component.invoke(noise, "process")
            noiseChannelNums[noise] = channel + 1
            if noiseChannelNums[noise] > 8 then
                noiseChannelNums[noise] = 1
            end
            wait()
        else
            computer.beep(freq, delay)
        end
    end
end

function sound.warn()
    sound.beep(100, 0.1, true)
    sound.beep(100, 0.1)
end

function sound.done()
    sound.beep(1800, 0.05, true)
    sound.beep(1800, 0.05)
end

sound.unloadable = true
return sound