local graphic = require("graphic")
local fs = require("filesystem")
local paths = require("paths")
local archiver = require("archiver")
local event = require("event")
local gui_container = require("gui_container")

local colors = gui_container.colors

--------------------------------------------

local screen, _, path = ...
local osizeX, osizeY = graphic.getResolution(screen)
local window
do
    local sizeX, sizeY = graphic.getResolution(screen)
    window = graphic.createWindow(screen, 1, 1, sizeX, sizeY)
end

local function printMainScreen(err)
    window:clear(colors.black)
    window:set(2, 1, colors.black, colors.gray, "Archiver")
    window:set(2, 3, colors.red, colors.white, "     close      ")
    window:set(2, 5, colors.green, colors.white, "     unpack     ")
    window:set(2, 7, colors.blue, colors.white, "      pack      ")

    if err then
        event.errLog("archiver error: " .. tostring(err))
        window:set(2, osizeY, colors.black, colors.gray, err)
    end
end

--[[
local function printBigScreen()
    window:clear(colors.black)
    window:set(2, 1, colors.black, colors.gray, "Archiver")
end
]]

--------------------------------------------

local function unpack(path, unpackFolder)
    gui_status(screen, nil, nil, "unpacking \"" .. gui_container.toUserPath(screen, path) .. "\" to \"" .. gui_container.toUserPath(screen, unpackFolder) .. "\"")
    --fs.remove(unpackFolder)
    fs.makeDirectory(unpackFolder)

    local ok, err = archiver.unpack(path, unpackFolder)
    if ok then
        printMainScreen()
    else
        printMainScreen(err)
    end
end

local function pack(packFolder, path)
    gui_status(screen, nil, nil, "packaging \"" .. gui_container.toUserPath(screen, packFolder) .. "\" to \"" .. gui_container.toUserPath(screen, path) .. "\"")
    local ok, err = archiver.pack(packFolder, path)
    if ok then
        printMainScreen()
    else
        printMainScreen(err)
    end
end

--------------------------------------------

printMainScreen()

while true do
    if path then
        --printBigScreen()
        printMainScreen()

        local unpackFolder = gui_filepicker(screen, nil, nil, nil, nil, true, true, true)
        if unpackFolder then
            unpack(path, unpackFolder)
        else
            printMainScreen()
        end

        path = nil
    end

    local eventData = {event.pull()}
    local windowEventData = window:uploadEvent(eventData)

    if windowEventData[1] == "touch" then
        if windowEventData[3] >= 3 and windowEventData[3] <= 18 then
            if windowEventData[4] == 3 then
                graphic.setResolution(screen, osizeX, osizeY)
                break
            elseif windowEventData[4] == 5 then
                --printBigScreen()
                printMainScreen()

                local archivePath = gui_filepicker(screen, nil, nil, nil, "afpx")
                local unpackFolder
                if archivePath then
                    unpackFolder = gui_filepicker(screen, nil, nil, nil, nil, true, true, true)
                end
                if archivePath and unpackFolder then
                    unpack(archivePath, unpackFolder)
                else
                    printMainScreen()
                end
            elseif windowEventData[4] == 7 then
                --printBigScreen()
                printMainScreen()

                local packFolder = gui_filepicker(screen, nil, nil, nil, nil, nil, true)
                local archivePath
                if packFolder then
                    archivePath = gui_filepicker(screen, nil, nil, nil, "afpx", true)
                end
                if archivePath and packFolder then
                    pack(packFolder, archivePath)
                else
                    printMainScreen()
                end
            end
        end
    end
end