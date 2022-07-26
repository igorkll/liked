local graphic = require("graphic")
local colors = require("gui_container").colors
local fs = require("filesystem")
local calls = require("calls")
local paths = require("paths")
local computer = require("computer")
local component = require("component")
local event = require("event")
local unicode = require("unicode")

local path = paths.path(calls.call("getPath"))
fs.makeDirectory(paths.concat(path, "profiles"))

local port = math.floor(math.random(1, 65535))
local range = 4

------------------------------------

local screen, nikname = ...
local rx, ry
do
    local gpu = graphic.findGpu(screen)
    rx, ry = gpu.getResolution()
end

local function status(str)
    local gpu = graphic.findGpu(screen)
    gpu.setBackground(colors.white)
    gpu.setForeground(colors.gray)
    gpu.fill(1, 1, rx, ry, " ")
    gpu.set(math.floor(((rx / 2) - (unicode.len(str) / 2)) + 0.5), math.floor((ry / 2) + 0.5), str)
end

------------------------------------

local modem
for address in component.list("modem") do
    if component.invoke(address, "isWireless") then
        modem = component.proxy(address)
        break
    end
end
if not modem then
    calls.call("gui_warn", screen, nil, nil, "wireless modem not found")
    return
end

function connectToNano()
    while true do
        local out = {nanoCall("setResponsePort", port)}
        if #out == 0 then
            if not calls.call("gui_yesno", screen, nil, nil, "no connection to nanomachines, try again?") then
                return true
            end
        else
            break
        end
    end
end

function nanoCall(func, ...)
    local status, err = modem.open(port)
    if not status and err == "to many open ports" then
        modem.close()
        return nanoCall(func, ...)
    end

    local strength = modem.setStrength(range)
    modem.broadcast(port, "nanomachines", func, ...)
    modem.setStrength(strength)

    local outdata = {event.pull(2, "modem_message", modem.address, nil, port, nil, "nanomachines")}
    if #outdata == 0 and func ~= "setResponsePort" then
        if connectToNano() then
            return nil, "exit"
        end
        return nanoCall(func, ...)
    end

    if status then
        modem.close(port)
    end

    return table.unpack(outdata, 7)
end

function createProfile()
    local tbl = {states = {}, notes = {}}
    local _, inputs = nanoCall("getTotalInputCount")
    if inputs == "exit" then
        return nil, "exit"
    end

    for i = 1, inputs do
        status("offing input: " .. tostring(i))
        local _, err = nanoCall("setInput", i, false)
        if err == "exit" then
            return nil, "exit"
        end
    end
    for i = 1, inputs do
        status("chicking input: " .. tostring(i))
        local _, err = nanoCall("setInput", i, true)
        if err == "exit" then
            return nil, "exit"
        end
        
        local _, note = nanoCall("getActiveEffects")
        if note == "exit" then
            return nil, "exit"
        end
        if note == "{}" then
            note = nil
        end

        tbl.states[i] = false
        tbl.notes[i] = note

        local _, err = nanoCall("setInput", i, false)
        if err == "exit" then
            return nil, "exit"
        end
    end
    return tbl
end

function getProfile(nikname)
    local path = paths.concat(path, "profiles", nikname)
    if not fs.exists(path) then
        local tbl, err = createProfile()
        if err == "exit" then
            return nil, "exit"
        end
        saveProfile(nikname, tbl)
        return tbl
    end
    local file = assert(fs.open(path, "rb"))
    local tbl = calls.call("unserialization", file.readAll())
    file.close()
    return tbl
end

function saveProfile(nikname, profile)
    local file = assert(fs.open(paths.concat(path, "profiles", nikname), "wb"))
    file.write(calls.call("serialization", profile))
    file.close()
    return true
end

if connectToNano() then
    return
end

------------------------------------

local _, totalInputCount = nanoCall("getTotalInputCount")
if totalInputCount == "exit" then
    return
end

------------------------------------

local window = graphic.createWindow(screen, 1, 1, rx, ry)

local function draw()
    window:clear(colors.white)
    window:set(1, 1, colors.white, colors.red, "X")
end

local function controlNote(nikname, profile, index)
    index = math.floor(index)

    local function draw()
        window:clear(colors.white)
        window:set(1, 1, colors.red, colors.white, "<")
        window:set(1, 2, colors.gray, colors.white, "profile: " .. nikname)

        window:set(1, 3, colors.gray, colors.white, "input info: " .. tostring(index) .. ":" .. tostring(profile.states[index]) .. ":" .. tostring(profile.notes[index] or "could not get input information"))

        window:set(1, 5, colors.gray, colors.white, "remove note")
        window:set(1, 6, colors.gray, colors.white, "new note")
    end
    draw()

    while true do
        local eventData = {computer.pullSignal()}
        local windowEventData = window:uploadEvent(eventData)

        if windowEventData[1] == "touch" then
            if windowEventData[3] == 1 and windowEventData[4] == 1 then
                break
            end
            if windowEventData[4] == 5 then
                profile.notes[index] = nil
                saveProfile(nikname, profile)
                draw()
            end
            if windowEventData[4] == 6 then
                local data = calls.call("gui_input", screen, nil, nil, "new note")
                if data then
                    profile.notes[index] = data
                    saveProfile(nikname, profile)
                end
                draw()
            end
        end
    end
end

local function controlFor(nikname)
    local window = graphic.createWindow(screen, 1, 1, rx, ry)

    local profile, err = assert(getProfile(nikname))
    if err == "exit" then
        return nil, "exit"
    end

    local function draw()
        window:clear(colors.white)
        window:set(1, 1, colors.red, colors.white, "X")
        window:set(1, 2, colors.gray, colors.white, "profile: " .. nikname)

        for i = 1, totalInputCount do
            window:fill(1, i + 2, rx, 1, colors.gray, 0, " ")
            local textcolor = colors.lightBlue
            if profile.states[i] then
                textcolor = colors.lime
            end
            window:set(1, i + 2, colors.gray, textcolor, tostring(i) .. ":" .. tostring(profile.notes[i] or "could not get input information"))
        end
    end
    draw()

    while true do
        local eventData = {computer.pullSignal()}
        local windowEventData = window:uploadEvent(eventData)

        if windowEventData[1] == "touch" then
            if windowEventData[3] == 1 and windowEventData[4] == 1 then
                break
            end
            if windowEventData[4] >= 3 then
                local index = windowEventData[4] - 2
                if index >= 1 and index <= totalInputCount then
                    if windowEventData[5] == 0 then
                        profile.states[index] = not profile.states[index]
                        local _, err = nanoCall("setInput", index, profile.states[index])
                        if err == "exit" then
                            return nil, "exit"
                        end
                        saveProfile(nikname, profile)
                        draw()
                    else
                        controlNote(nikname, profile, index)
                        draw()
                    end
                end
            end
        end
    end
end

status("pleas wait")
controlFor(nikname)