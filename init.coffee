fs     = require "fs"

server = require("./server")
cache  = require("./cache").cache
sp = require("./static_content_provider")
router = require("./router/router")


router.initRouter cache
sp.loadStaticFiles cache
server.initServer cache
