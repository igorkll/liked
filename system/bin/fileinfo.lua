local screen, nickname, path = ...

local graphic = require("graphic")
local gui_container = require("gui_container")
local colors = gui_container.colors
local event = require("event")
local fs = require("filesystem")
local paths = require("paths")

local cx, cy = graphic.getResolution(screen)
cx = cx / 2
cy = cy / 2
cx = cx - 25
cy = cy - 8
cx = math.floor(cx + 0.5)
cy = math.floor(cy + 0.5)

local window = graphic.createWindow(screen, cx, cy, 50, 16, true)
window:clear(colors.white)
window:fill(1, 1, window.sizeX, 1, colors.gray, 0, " ")
window:set(window.sizeX, 1, colors.red, colors.white, "X")
window:set(2, 1, colors.gray, colors.white, "file-info")

local ctype = fs.isDirectory(path) and "directory" or "file"
local exp = paths.extension(path)
if exp then
    ctype = (gui_container.typenames[exp] or exp) .. "-" .. ctype
end

local addr = fs.get(path).address

window:set(2, 3, colors.white, colors.black, "type  : " .. ctype)
window:set(2, 4, colors.white, colors.black, "path  : " .. gui_container.shortPath(path, #addr))
window:set(2, 5, colors.white, colors.black, "disk  : " .. addr)
window:set(2, 6, colors.white, colors.black, "size  : " .. tostring(math.roundTo(fs.size(path) / 1024, 1)) .. "KB")

local sum = "-"
if not fs.isDirectory(path) and fs.size(path) <= (16 * 1024) then
    local content = fs.readFile(path)
    if content then
        window:set(2, 7, colors.white, colors.black, "sha256: please wait...")
        sum = require("sha256").sha256hex(content)
        sum = sum:sub(1, #addr) .. gui_container.chars.threeDots
    end
end
window:set(2, 7, colors.white, colors.black, "sha256: " .. sum)

while true do
    local eventData = {event.pull()}
    local windowEventData = window:uploadEvent(eventData)

    if windowEventData[1] == "key_down" then
        if windowEventData[4] == 28 then
            break
        end
    elseif windowEventData[1] == "touch" then
        if windowEventData[3] == window.sizeX and windowEventData[4] == 1 then
            break
        end
    end
end