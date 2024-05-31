local fs = require("filesystem")
fs.mount(fs.dump("/home", nil, nil, true), "/data/userdata/openOS_files")