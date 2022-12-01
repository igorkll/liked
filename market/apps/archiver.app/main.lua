local graphic = require("graphic")
local fs = require("filesystem")
local paths = require("paths")
local afpx = require("afpx")
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
    graphic.setResolution(screen, 20, 8)
    window:clear(colors.black)
    window:set(7, 1, colors.black, colors.gray, "Archiver")
    window:set(3, 3, colors.red, colors.white, "     close      ")
    window:set(3, 5, colors.green, colors.white, "     unpack     ")
    window:set(3, 7, colors.blue, colors.white, "      pack      ")

    if err then
        event.errLog(err)
        window:set(1, 8, colors.black, colors.gray, err)
    end
end

local function printBigScreen()
    graphic.setResolution(screen, osizeX, osizeY)
    window:clear(colors.black)
    window:set(1, 1, colors.black, colors.gray, "Archiver")
end

--------------------------------------------

local function unpack(path, unpackFolder)
    fs.remove(unpackFolder)
    fs.makeDirectory(unpackFolder)

    local ok, err = afpx.unpack(path, unpackFolder)
    if ok then
        printMainScreen()
    else
        printMainScreen(err)
    end
end

local function pack(packFolder, path)
    local ok, err = afpx.pack(packFolder, path)
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
        printBigScreen()

        local unpackFolder = gui_filepicker(screen, nil, nil, nil, nil, true, true)

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
                printBigScreen()
                local archivePath = gui_filepicker(screen, nil, nil, nil, "afpx")
                local unpackFolder
                if archivePath then
                    unpackFolder = gui_filepicker(screen, nil, nil, nil, nil, true, true)
                end
                if archivePath and unpackFolder then
                    unpack(archivePath, unpackFolder)
                else
                    printMainScreen()
                end
            elseif windowEventData[4] == 7 then
                printBigScreen()
                local packFolder = gui_filepicker(screen, nil, nil, nil, nil, nil, true)
                local archivePath
                if packFolder then
                    archivePath = gui_filepicker(screen, nil, nil, nil, "afpx", true)
                end
                if archivePath and packFolder then
                    local ok, err = afpx.pack(packFolder, archivePath)
                    if ok then
                        printMainScreen()
                    else
                        printMainScreen(err)
                    end
                else
                    printMainScreen()
                end
            end
        end
    end
end