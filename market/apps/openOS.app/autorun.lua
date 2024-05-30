local fs = require("filesystem")
fs.mount(fs.dump("/home", true, nil, true), "/data/userdata/openOS_files")