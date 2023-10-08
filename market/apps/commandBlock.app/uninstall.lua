local registry = require("registry")
local system = require("system")
local paths = require("paths")
local liked = require("liked")
local fs = require("filesystem")

registry.icons["cbs"] = nil
liked.reg("openVia", "cbs", nil)
liked.reg("editable", "cbs", nil)

fs.remove(paths.path(system.getSelfScriptPath()))