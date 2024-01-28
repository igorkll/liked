local paths = require("paths")
local fs = require("filesystem")

fs.remove("/dev") --я знаю что это "виртуальные" директории, но они тоже могут создасться
fs.remove("/mnt")

fs.remove("/usr")
fs.remove("/home")
fs.remove("/etc")
fs.remove("/boot")
fs.remove("/lib")
fs.remove("/bin")
fs.remove("/openOS.lua")

fs.remove("/autorun.lua")
fs.remove("/.autorun.lua")

fs.remove(paths.path(getPath()))