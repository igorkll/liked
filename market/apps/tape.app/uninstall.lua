local registry = require("registry")
local system = require("system")
local paths = require("paths")
local liked = require("liked")
local fs = require("filesystem")

registry.icons["dfpwm"] = nil
liked.reg("openVia", "dfpwm", nil)
liked.reg("knownExps", "dfpwm", nil)

fs.remove(paths.path(system.getSelfScriptPath()))