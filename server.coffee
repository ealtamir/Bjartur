spdy   = require "spdy"
fs     = require "fs"
config = require("./lib/config").config

initServer = () ->
  options =
    key   : fs.readFileSync 'keys/server.key'
    cert  : fs.readFileSync 'keys/server.crt'
    ca    : fs.readFileSync 'keys/server.csr'

  server = spdy.createServer options, (req, res) ->
    res.writeHead 200
    res.end "Hello World!"

  server.listen config.https_port

  console.log "\n\n == Server started at port #{config.https_port} ==\n\n"

initServer()
