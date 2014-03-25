fs     = require "fs"

server = require("./server")
cache  = require("./cache").cache
sp = require("./static_content_provider")

sp.loadStaticFiles cache
server.initServer cache
