local graphic = require("graphic")
local component = require("component")
local event = require("event")
local calls = require("calls")

------------------------------------

local screen = "20108ef5-444e-46bc-bd6c-48aee518009e"
calls.call("initScreen", screen)

local rx, ry = graphic.findGpu(screen).getResolution()

calls.call("gui_warn", screen, "asdasd")