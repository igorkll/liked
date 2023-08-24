local paths = require("paths")
local fs = require("filesystem")

fs.remove("/Mounts") --я знаю что это "виртуальные" директории, но они тоже могут создасться

fs.remove("/Applications")
fs.remove("/Extensions")
fs.remove("/Icons")
fs.remove("/Libraries")
fs.remove("/Localizations")
fs.remove("/Pictures")
fs.remove("/Screensavers")
fs.remove("/Temporary")
fs.remove("/Users")
fs.remove("/Versions.cfg")
fs.remove("/OS.lua")

fs.remove("/mineOS.lua")
fs.remove(paths.path(getPath()))