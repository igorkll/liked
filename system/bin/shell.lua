local liked = require("liked")
local thread = require("thread")
local screen = ...

assert(liked.execute("login", screen))
assert(liked.execute("desktop", screen))