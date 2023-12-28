local thread = require("thread")
local component = require("component")
local computer = require("computer")
local note = require("note")
local bit32 = require("bit32")
local fs = require("filesystem")

local oldInterruptTime = computer.uptime()
local function interrupt()
    if computer.uptime() - oldInterruptTime > 2 then
        os.sleep(0)
        oldInterruptTime = computer.uptime()
    end
end

-------------------------------------------------------

local lib = {}

local square = 1
local sine = 2
local triangle = 3
local sawtooth = 4
local midiToWave = {
    [  2] = square,
    [  4] = square,
    [  5] = square,
    -- celesta
    [  8] = sine,
    -- glockenspiel
    [  9] = sawtooth,
    -- music box
    [ 10] = sine,
    -- vibraphone
    [ 11] = sine,
    -- marimba
    [ 12] = sine,
    -- xylophone
    [ 13] = sine,
    -- tubular bells
    [ 14] = sawtooth,
    -- Guitars
    [ 24] = triangle,
    [ 25] = triangle,
    [ 26] = triangle,
    [ 27] = triangle,
    [ 28] = triangle,
    [ 29] = triangle,
    [ 30] = triangle,
    [ 31] = triangle,
    -- Basses
    [32] = sawtooth,
    [33] = sawtooth,
    [34] = sawtooth,
    [35] = sawtooth,
    [36] = sawtooth,
    [37] = sawtooth,
    [38] = sawtooth,
    [39] = sawtooth,
    -- Pipes
    [72] = sine,
    [73] = sine,
    [74] = sine,
    [75] = sine,
    [76] = sine,
    [77] = sine,
    [78] = sine,
    [79] = sine,
    -- square wave
    [80] = square,
    -- banjo
    [105] = square,
    -- tinkle bell
    [112] = sine,
}

function lib.programToWave(program)
    return midiToWave[program]
end




--piano = 0
--drum = 1
--sticks = 2
--smallDrum = 3
--bassGuitar = 4
--xylophone = 5
local glowstone = 3
local iron_block = 0
local gold_block = 0
local bone_block = 2
local white_wool = 0
local acacia_log = 4
local clay = 1
local hay_block = 2
local packed_ice = 0
local emerald_block = 0

local midiToNote = {
    [  2] = glowstone,
    [  4] = glowstone,
    [  5] = glowstone,
    -- celesta
    [  8] = iron_block,
    -- glockenspiel
    [  9] = gold_block,
    -- music box
    [ 10] = iron_block,
    -- vibraphone
    [ 11] = iron_block,
    -- marimba
    [ 12] = iron_block,
    -- xylophone
    [ 13] = bone_block,
    -- tubular bells
    [ 14] = gold_block,
    -- Guitars
    [ 24] = white_wool,
    [ 25] = white_wool,
    [ 26] = white_wool,
    [ 27] = white_wool,
    [ 28] = white_wool,
    [ 29] = white_wool,
    [ 30] = white_wool,
    [ 31] = white_wool,
    -- Basses
    [32] = acacia_log,
    [33] = acacia_log,
    [34] = acacia_log,
    [35] = acacia_log,
    [36] = acacia_log,
    [37] = acacia_log,
    [38] = acacia_log,
    [39] = acacia_log,
    -- Pipes
    [72] = clay,
    [73] = clay,
    [74] = clay,
    [75] = clay,
    [76] = clay,
    [77] = clay,
    [78] = clay,
    [79] = clay,
    -- square wave
    [80] = emerald_block,
    -- banjo
    [105] = hay_block,
    -- tinkle bell
    [112] = packed_ice,
}

function lib.programToNote(program)
    return midiToNote[program]
end





function lib.instruments()
    local instruments, beeps = {}, {}
 
    table.insert(instruments, function(beep)
        table.insert(beeps, beep)
    end)

    local iters = {}
    local function getComponent(name, notRecurse)
        if not iters[name] then
            iters[name] = component.list(name, true)
        end

        local device = iters[name]()
        if not device and not notRecurse then
            iters[name] = nil
            device = getComponent(name, true)
        end
        return device
    end

    local function clamp(freq)
        if freq < 20 then return 20 end
        if freq > 2000 then return 2000 end
        return freq
    end

    local noiseChannel = {}
    
    function instruments.flush()
        local devicesCount = 0
        for address in component.list("note_block", true) do devicesCount = devicesCount + 1 end
        for address in component.list("iron_noteblock", true) do devicesCount = devicesCount + 1 end
        for address in component.list("beep", true) do devicesCount = devicesCount + 1 end
        for address in component.list("noise", true) do devicesCount = devicesCount + 1 end

        if devicesCount > 0 then
            local noiseCards = {}
            for i, beep in ipairs(beeps) do
                local cbeep = getComponent("beep")
                local note_block = getComponent("note_block")
                local iron_noteblock = getComponent("iron_noteblock")
                local noise = getComponent("noise")

                if cbeep then
                    component.invoke(cbeep, "beep", {[clamp(beep.freq)] = beep.time})
                end

                if note_block then
                    component.invoke(note_block, "trigger", (beep.note + 6 - 60) % 24 + 1)
                end

                if iron_noteblock then
                    component.invoke(iron_noteblock, "playNote", beep.track.program and lib.programToNote(beep.track.program) or 0, (beep.note + 6 - 60) % 24, beep.volume or 1)
                end

                if noise then
                    noise = component.proxy(noise)
                    if not noiseCards[noise] then
                        noiseCards[noise] = {}
                    end
                    table.insert(noiseCards[noise], beep)
                end
            end

            for noise, beeps in pairs(noiseCards) do
                for i, beep in ipairs(beeps) do
                    local channel = noiseChannel[noise.address] or 1
                    noiseChannel[noise.address] = channel + 1
                    if channel > 8 then
                        channel = 1
                        noiseChannel[noise.address] = 2
                    end

                    noise.setMode(channel, beep.track.program and lib.programToWave(beep.track.program) or 1)
                    noise.add(channel, clamp(beep.freq), beep.time)
                end

                noise.process()
            end
        else
            for i = 1, #beeps do
                computer.beep(clamp(beeps[i].freq), beeps[i].time)
            end
        end

        beeps = {}
    end

    return instruments
end

function lib.create(filepath, instruments)
    local obj = {}
    obj.filepath = filepath
    obj.instruments = instruments

    obj.speed = 1
    obj.duration = 1
    obj.pitch = 1

    function obj.play()
        local instruments = obj.instruments
        local filename = obj.filepath
    
        local function beepableFrequency(midiCode, returnMidiCode)
            local freq = note.freq(midiCode) * obj.pitch
            if returnMidiCode then
                return note.midi(freq)
            else
                return freq
            end
        end
    
        local f, reason = fs.open(filename, "rb", true)
        if not f then
            return nil, reason
        end

        f.bufferRead = ""
        local fread = f.read
        function f.read(n)
            if #f.bufferRead > 0 then
                local s = f.bufferRead:sub(1, n)
                f.bufferRead = f.bufferRead:sub(n + 1, #f.bufferRead)
                return s
            else
                return fread(n)
            end
        end
    
        local function parseVarInt(s, bits) -- parses multiple bytes as an integer
            if not s then
                return nil, "error parsing file"
            end
            bits = bits or 8
            local mask = bit32.rshift(0xFF, 8 - bits)
            local num = 0
            for i = 1, s:len() do
                num = num + bit32.lshift(bit32.band(s:byte(i), mask), (s:len() - i) * bits)
            end
            return num
        end
    
        local function readChunkInfo() -- reads chunk header info
            local id = f.read(4)
            if not id then
                return
            end
            return id, parseVarInt(f.read(4))
        end
    
        -- Read the file header and with if file information.
        local id, size = readChunkInfo()
        if id ~= "MThd" or size ~= 6 then
            return nil, "error parsing header (" .. id .. "/" .. size .. ")"
        end
    
        local format = parseVarInt(f.read(2))
        local tracks = parseVarInt(f.read(2))
        local delta = parseVarInt(f.read(2))
    
        if format < 0 or format > 2 then
            return nil, "unknown format"
        end
    
        local formatName = ({"single", "synchronous", "asynchronous"})[format + 1]
        --print(string.format("Found %d %s tracks.", tracks, formatName))
    
        if format == 2 then
            return nil, "Sorry, asynchronous tracks are not supported."
        end
    
        -- Figure out our time system and prepare accordingly.
        local time = {division = bit32.band(0x8000, delta) == 0 and "tpb" or "fps"}
        if time.division == "tpb" then
            time.tpb = bit32.band(0x7FFF, delta)
            time.mspb = 500000
            function time.tick()
                return time.mspb / time.tpb
            end
            --print(string.format("Time division is in %d ticks per beat.", time.tpb))
        else
            time.fps = bit32.band(0x7F00, delta)
            time.tpf = bit32.band(0x00FF, delta)
            function time.tick()
                return 1000000 / (time.fps * time.tpf)
            end
            --print(string.format("Time division is in %d frames per second with %d ticks per frame.", time.fps, time.tpf))
        end
        function time.calcDelay(later, earlier)
            return (later - earlier) * time.tick() / 1000000
        end
    
        -- Parse all track chunks.
        local totalOffset = 0
        local totalLength = 0
        local tracks = {}
        while true do
            interrupt()            
            local id, size = readChunkInfo()
            if not id then
                break
            end
            if id == "MTrk" then
                local track = {}
                local cursor = 0
                --local start, offset = f.seek(), 0
                local start, offset = 0, 0
                local inSysEx = false
                local running = 0
    
                local function read(n)
                    n = n or 1
                    if n > 0 then
                        offset = offset + n
                        return f.read(n)
                    end
                end
                local function readVariableLength()
                    local total = ""
                    for i = 1, math.huge do
                        local part = read()
                        total = total .. part
                        if bit32.band(0x80, part:byte(1)) == 0 then
                            return parseVarInt(total, 7)
                        end
                    end
                end
                local function parseVoiceMessage(event)
                    local channel = bit32.band(0xF, event)
                    local note = parseVarInt(read())
                    local velocity = parseVarInt(read())
                    return channel, note, velocity
                end
                local currentNoteEvents = {}
                local function noteOn(cursor, channel, note, velocity)
                    track[cursor] = {channel, note, velocity}
                    if not currentNoteEvents[channel] then
                        currentNoteEvents[channel] = {}
                    end
                    currentNoteEvents[channel][note] = {event=track[cursor], tick=cursor}
                end
                local function noteOff(cursor, channel, note, velocity)
                    if not (currentNoteEvents[channel] and currentNoteEvents[channel][note]) then return end
                    table.insert(currentNoteEvents[channel][note].event
                            , time.calcDelay(cursor, currentNoteEvents[channel][note].tick))
                    currentNoteEvents[channel][note] = nil
                end
    
                while offset < size do
                    interrupt()                    
                    cursor = cursor + readVariableLength()
                    totalLength = math.max(totalLength, cursor)
                    local test = parseVarInt(read())
                    if inSysEx and test ~= 0xF7 then
                        return nil, "corrupt file: could not find continuation of divided sysex event"
                    end
                    local event
                    if bit32.band(test, 0x80) == 0 then
                        if running == 0 then
                            return nil, "corrupt file: invalid running status"
                        end
                        f.bufferRead = string.char(test) .. f.bufferRead
                        offset = offset - 1
                        event = running
                    else
                        event = test
                        if test < 0xF0 then
                            running = test
                        end
                    end
                    local status = bit32.band(0xF0, event)
                    if status == 0x80 then -- Note off.
                        local channel, note, velocity = parseVoiceMessage(event)
                        noteOff(cursor, channel, note, velocity)
                    elseif status == 0x90 then -- Note on.
                        local channel, note, velocity = parseVoiceMessage(event)
                        if velocity == 0 then
                            noteOff(cursor, channel, note, velocity)
                        else
                            noteOn(cursor, channel, note, velocity)
                        end
                    elseif status == 0xA0 then -- Aftertouch / key pressure
                        parseVoiceMessage(event) -- not handled
                    elseif status == 0xB0 then -- Controller
                        parseVoiceMessage(event) -- not handled
                    elseif status == 0xC0 then -- Program change
                        track.program = parseVarInt(read()) -- not handled
                    elseif status == 0xD0 then -- Channel pressure
                        parseVarInt(read()) -- not handled
                    elseif status == 0xE0 then -- Pitch / modulation wheel
                        parseVarInt(read(2), 7) -- not handled
                    elseif event == 0xF0 then -- System exclusive event
                        local length = readVariableLength()
                        if length > 0 then
                            read(length - 1)
                            inSysEx = read(1):byte(1) ~= 0xF7
                        end
                    elseif event == 0xF1 then -- MIDI time code quarter frame
                        parseVarInt(read()) -- not handled
                    elseif event == 0xF2 then -- Song position pointer 
                        parseVarInt(read(2), 7) -- not handled
                    elseif event == 0xF3 then -- Song select
                        parseVarInt(read(2), 7) -- not handled
                    elseif event == 0xF7 then -- Divided system exclusive event
                        local length = readVariableLength()
                        if length > 0 then
                            read(length - 1)
                            inSysEx = read(1):byte(1) ~= 0xF7
                        else
                            inSysEx = false
                        end
                    elseif event >= 0xF8 and event <= 0xFE then -- System real-time event
                        -- not handled
                    elseif event == 0xFF then
                        -- Meta message.
                        local metaType = parseVarInt(read())
                        local length = parseVarInt(read())
                        local data = read(length)
    
                        if metaType == 0x00 then -- Sequence number
                            track.sequence = parseVarInt(data)
                        elseif metaType == 0x01 then -- Text event
                        elseif metaType == 0x02 then -- Copyright notice
                        elseif metaType == 0x03 then -- Sequence / track name
                            track.name = data
                        elseif metaType == 0x04 then -- Instrument name
                            track.instrument = data
                        elseif metaType == 0x05 then -- Lyric text
                        elseif metaType == 0x06 then -- Marker text
                        elseif metaType == 0x07 then -- Cue point
                        elseif metaType == 0x20 then -- Channel prefix assignment
                        elseif metaType == 0x2F then -- End of track
                            track.eot = cursor
                        elseif metaType == 0x51 then -- Tempo setting
                            track[cursor] = parseVarInt(data)
                        elseif metaType == 0x54 then -- SMPTE offset
                        elseif metaType == 0x58 then -- Time signature
                        elseif metaType == 0x59 then -- Key signature
                        elseif metaType == 0x7F then -- Sequencer specific event
                        end
                    else
                        f.seek("cur", -9)
                        local area = f.read(16)
                        local dump = ""
                        for i = 1, area:len() do
                            dump = dump .. string.format(" %02X", area:byte(i))
                            if i % 4 == 0 then
                                dump = dump .. "\n"
                            end
                        end
                        return nil, string.format("midi file contains unhandled event types:\n0x%X at offset %d/%d\ndump of the surrounding area:\n%s", event, offset, size, dump)
                    end
                end
                -- turn off any remaining notes
                for iChannel, iNotes in pairs(currentNoteEvents) do
                    for iNote, iEntry in pairs(currentNoteEvents[iChannel]) do
                        noteOff(cursor, iChannel, iNote)
                    end
                end
                local delta = size - offset
                if delta ~= 0 then
                    f.seek("cur", delta)
                end
                totalOffset = totalOffset + size
                table.insert(tracks, track)
            else
                --print(string.format("Encountered unknown chunk type %s, skipping.", id))
                f.seek("cur", size)
            end
        end
    
        f.close()
    
        --print("Playing " .. #tracks .. " tracks:")
        --[[
        for _, track in ipairs(tracks) do
            if track.name then
                --print(string.format("%s", track.name))
            end
        end
        ]]
    
        local channels = {n=0}
        local lastTick, lastTime = 0, computer.uptime()
        --print("Press Ctrl+C to exit.")
        for tick = 1, totalLength do
            local hasEvent = false
            for _, track in ipairs(tracks) do
                if track[tick] then
                    hasEvent = true
                    break
                end
            end
            if hasEvent then
                local delay = time.calcDelay(tick, lastTick) / obj.speed
                if delay > 0 then
                    -- delay % 0.05 == 0 doesn't seem to work
                    if delay > 0.05 then
                        os.sleep(delay)
                    else
                        -- Busy idle otherwise, because a sleep will take up to 50ms.
                        local begin = os.clock()
                        while os.clock() - begin < delay do end
                    end
                end

                lastTick = tick
                lastTime = computer.uptime()
                for _, track in ipairs(tracks) do
                    local event = track[tick]
                    interrupt()
                    if event then
                        if type(event) == "number" then
                            time.mspb = event
                        elseif type(event) == "table" then
                            local channel, note, velocity, duration = table.unpack(event)
                            local instrument
                            if not channels[channel] then
                                channels.n = channels.n + 1
                                channels[channel] = instruments[1 + ((channels.n - 1) % #instruments)]
                            end
                            if not duration then duration = 0 end
                            if not note then note = 1 end
                            if not channel then channel = "nil" end

                            local beep = {}
                            beep.freq = beepableFrequency(note)
                            beep.note = beepableFrequency(note, true)
                            beep.time = duration * obj.duration
                            beep.volume = velocity / 127
                            beep.track = track
                            beep.event = event

                            if channels[channel] and channels[channel](beep) then
                                break
                            end
                        end
                    end
                end
                if instruments.flush then instruments.flush() end
            end
        end
        return true
    end

    obj.loop = function()
        while true do
            local ok, err = obj.play()
            if not ok then
                return nil, err
            end
            os.sleep()
        end
    end

    obj.createThread = function(loop)
        if loop then
            return thread.create(function() local ok, err = obj.loop() if not ok then error(err, 2) end end)
        else
            return thread.create(function() local ok, err = obj.play() if not ok then error(err, 2) end end)
        end
    end

    obj.createBackgroundThread = function(loop)
        if loop then
            return thread.createBackground(function() local ok, err = obj.loop() if not ok then error(err, 2) end end)
        else
            return thread.createBackground(function() local ok, err = obj.play() if not ok then error(err, 2) end end)
        end
    end

    return obj
end

lib.unloadable = true
return lib