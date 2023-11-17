local liked = require("liked")
local screen = ...



assert(liked.execute("login", screen))
assert(liked.execute("desktop", screen))