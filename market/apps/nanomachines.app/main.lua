local graphic = require("graphic")
local colors = require("gui_container").colors
local fs = require("filesystem")
local paths = require("paths")
local computer = require("computer")
local component = require("component")
local event = require("event")
local unicode = require("unicode")
local thread = require("thread")
local serialization = require("serialization")
local liked = require("liked")

local path = paths.path(getPath())
fs.makeDirectory(paths.concat(path, "profiles"))

local port = math.floor(math.random(1, 65535))
local range = 3

local title = "Nanomachines"

------------------------------------ init

local screen, nickname = ...
local rx, ry
do
    local gpu = graphic.findGpu(screen)
    rx, ry = gpu.getResolution()
end

local upth, upRedraw = liked.drawUpBarTask(screen, true, colors.lightGray)
upth:suspend()

local function noUpBar()
    upth:suspend()
end

local function upBar()
    upth:resume()
    upRedraw()
end

local function status(str)
    local gpu = graphic.findGpu(screen)
    gpu.setBackground(colors.gray)
    gpu.setForeground(colors.white)
    gpu.fill(1, 1, rx, ry, " ")
    gpu.set(math.floor(((rx / 2) - (unicode.len(str) / 2)) + 0.5) + 1, math.floor((ry / 2) + 0.5) - 1, str)
    graphic.forceUpdate()
    --gui_status(screen, nil, nil, str)
end

local modem
for address in component.list("modem") do
    if component.invoke(address, "isWireless") then
        modem = component.proxy(address)
        break
    end
end
if not modem then
    gui_warn(screen, nil, nil, "wireless modem not found")
    return
end

------------------------------------ methods

function yesno_reconnect()
    return gui_yesno(screen, nil, nil, "no connection to nanomachines, try again?")
end

function connectToNano()
    noUpBar()
    while true do
        status("connecting to nanomachines...")
        local out = {nanoCall("setResponsePort", port)}
        if #out == 0 then
            if not yesno_reconnect() then
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

function raw_nanoCall(func, ...)
    local status, err = modem.open(port)
    if not status and err == "to many open ports" then
        modem.close()
        return raw_nanoCall(func, ...)
    end

    local strength = modem.setStrength(range)
    modem.broadcast(port, "nanomachines", func, ...)
    modem.setStrength(strength)

    local outdata = {event.pull(2, "modem_message", modem.address, nil, port, nil, "nanomachines")}
    if #outdata == 0 and func ~= "setResponsePort" then
        return nil, "exit"
    end

    if status then
        modem.close(port)
    end

    return table.unpack(outdata, 7)
end

function pushAll(tbl, inputs)
    noUpBar()
    for i = 1, inputs do
        status("pushing input: " .. tostring(i) .. "/" .. tostring(math.floor(inputs)))
        local _, err = nanoCall("setInput", i, tbl[i])
        if err == "exit" then
            return nil, "exit"
        end
    end
end

function pullAll(tbl, inputs)
    noUpBar()
    for i = 1, inputs do
        status("checking input: " .. tostring(i) .. "/" .. tostring(math.floor(inputs)))
        local _, err, state = nanoCall("getInput", i)
        if err == "exit" then
            return nil, "exit"
        end
        tbl[i] = state
    end
end

function createProfile()
    local tbl = {states = {}, notes = {}}

    local _, inputs = nanoCall("getTotalInputCount")
    if inputs == "exit" then
        return nil, "exit"
    end

    for i = 1, inputs do
        tbl.notes[i] = false
    end

    local _, err = pullAll(tbl.states, inputs)
    if err == "exit" then
        return nil, "exit"
    end

    return tbl
end

function getProfile(nickname)
    local path = paths.concat(path, "profiles", nickname)
    if not fs.exists(path) then
        local tbl, err = createProfile()
        if err == "exit" then
            return nil, "exit"
        end
        saveProfile(nickname, tbl)
        return tbl
    end
    local file = assert(fs.open(path, "rb"))
    local tbl = serialization.unserialize(file.readAll())
    file.close()
    return tbl
end

function saveProfile(nickname, profile)
    local file = assert(fs.open(paths.concat(path, "profiles", nickname), "wb"))
    file.write(serialization.serialize(profile))
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
local readers

--[[
local function controlNote(nickname, profile, index)
    index = math.floor(index)

    local function draw()
        window:clear(colors.white)
        window:set(rx, 1, colors.red, colors.white, "X")
        window:set(1, 1, colors.red, colors.white, "<")
        window:set(1, 2, colors.gray, colors.white, "profile: " .. nickname)

        window:set(1, 3, colors.gray, colors.white, "input info: " .. tostring(index) .. ":" .. tostring(profile.states[index]) .. ":" .. tostring(profile.notes[index] or "no note"))

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
            if windowEventData[3] == rx and windowEventData[4] == 1 then
                return true
            end

            if windowEventData[4] == 5 then
                profile.notes[index] = nil
                saveProfile(nickname, profile)
                draw()
            end
            if windowEventData[4] == 6 then
                local data = calls.call("gui_input", screen, nil, nil, "new note")
                if data then
                    profile.notes[index] = data
                    saveProfile(nickname, profile)
                end
                draw()
            end
        end
    end
end
]]

-------------------------------------------

local profile, err = assert(getProfile(nickname))
if err == "exit" then
    return nil, "exit"
end

local gchange = {}
local connectErr
local dataUpdate
local tryClose

local th = thread.create(function ()
    while true do
        if not connectErr then
            local saveData
            for index, state in pairs(gchange) do
                if state ~= nil then
                    local _, err = raw_nanoCall("setInput", index, state)
                    if err == "exit" then
                        connectErr = true
                    else
                        if gchange[index] == state then
                            profile.states[index] = gchange[index]
                            saveData = true

                            gchange[index] = nil
                            dataUpdate = true
                        end
                    end
                end
            end
            if saveData then
                saveProfile(nickname, profile)
            end    
        end

        os.sleep(0.1)
    end
end)
th:resume()

local function draw()
    if not readers then
        readers = {}
        for i = 1, totalInputCount do
            readers[i] = window:read(4, 5 + i, 32, colors.gray, colors.white, nil, nil, nil, true)
            readers[i].setBuffer(profile.notes[i] or "")
        end
    end

    window:clear(colors.black)
    
    window:fill(1, 1, rx, 1, colors.lightGray, 0, " ")
    window:set(2, 1, colors.lightGray, colors.white, title)
    upBar()

    window:set(rx, 1, colors.red, colors.white, "X")
    window:set(1, 2, colors.red, colors.white, "delete profile")
    window:set(16, 2, colors.orange, colors.white, "push all")
    window:set(25, 2, colors.green, colors.white, "pull all")
    window:set(1, 3, colors.gray, colors.white, "profile: " .. nickname)

    window:fill(4, 5, 32, 1, colors.gray, 0, " ")
    window:set(4, 5, colors.gray, colors.white, "notes:")

    for i = 1, #readers do
        local textcolor

        local newval = gchange[i]
        if newval ~= nil then
            textcolor = newval and colors.yellow or colors.blue
        else
            textcolor = profile.states[i] and colors.lime or colors.lightBlue
        end

        local si = tostring(i)
        if #si == 1 then
            si = si .. " "
        end
        --window:set(1, i + 2, colors.gray, textcolor, si .. ":" .. tostring(profile.notes[i] or "no note"))
        window:set(1, 5 + i, colors.gray, textcolor, si)
        readers[i].redraw()
    end
end
draw()

while true do
    local eventData = {computer.pullSignal(0.5)}
    local windowEventData = window:uploadEvent(eventData)

    for i = 1, #readers do
        local allowUse = readers[i].getAllowUse()
        if not allowUse and readers[i].oldAllowUse then
            local buff = readers[i].getBuffer()
            if buff ~= (profile.notes[i] or "") then
                profile.notes[i] = buff
                saveProfile(nickname, profile)
            end
        end
        readers[i].oldAllowUse = allowUse
    end

    for i = 1, #readers do
        local ret = readers[i].uploadEvent(windowEventData)
        if ret == true then
            readers[i].setBuffer(profile.notes[i] or "")
            readers[i].setAllowUse(false)
            readers[i].redraw()
        elseif ret then
            profile.notes[i] = ret
            saveProfile(nickname, profile)
            readers[i].setAllowUse(false)
            readers[i].redraw()
        end
    end

    if windowEventData[1] == "touch" then
        if windowEventData[4] == 1 then
            if windowEventData[3] == rx then
                tryClose = true
            end
        end
        if windowEventData[4] == 2 then
            if windowEventData[3] >= 1 and windowEventData[3] <= 14 then
                if gui_yesno(screen, nil, nil, "are you sure you want to delete your profile and exit the app?") then
                    fs.remove(paths.concat(path, "profiles", nickname))
                    break
                end
                draw()
            elseif windowEventData[3] >= 16 and windowEventData[3] <= (16 + 7) then
                for index, state in pairs(gchange) do
                    if state ~= nil then
                        profile.states[index] = gchange[index]
                    end
                end
                gchange = {}
                pushAll(profile.states, totalInputCount)
                saveProfile(nickname, profile)
                draw()
            elseif windowEventData[3] >= 25 and windowEventData[3] <= (25 + 7) then
                gchange = {}
                pullAll(profile.states, totalInputCount)
                saveProfile(nickname, profile)
                draw()
            end
        end

        if windowEventData[4] >= 6 and windowEventData[3] <= 2 then
            local index = windowEventData[4] - 5
            if index >= 1 and index <= totalInputCount then
                local state = gchange[index]
                if state == nil then
                    state = profile.states[index]
                end
                gchange[index] = not state
                draw()
            end
        end
    end

    if connectErr then
        if connectToNano() then
            break
        else
            connectErr = nil
            dataUpdate = nil
            draw()
        end
    elseif dataUpdate then
        draw()
        dataUpdate = nil
    end

    local noClose
    for key, value in pairs(gchange) do
        if value ~= nil then
            noClose = true
            break
        end
    end
    if tryClose and not noClose then
        break
    end
end

th:kill()