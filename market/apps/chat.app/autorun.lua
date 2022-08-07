_G.chat_allow = true

require("chat_lib")
table.insert(require("gui_container").filesExps, {nil, "chat", "send file to chat", true, false})
table.insert(require("gui_container").filesExps, {"t2p", "chat", "send image to chat", true, false, ":image"})