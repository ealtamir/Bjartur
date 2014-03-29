fs    = require "fs"
http  = require "http"
spdy  = require "spdy"
url   = require "url"

cache         =  require("./cache").cache
config        =  require("./lib/config").config
eventAggr     =  require("./event_aggregator").eventAggregator
fetchContent  =  require("./static_content_provider").fetchContent
send404       =  require("./static_content_provider").send404

exports.initServer = (cache) ->
  startSPDY()
  startHTTP()

  console.log "\n == SPDY server started at port #{config.https_port} ==\n"


startSPDY = () ->
  options =
    key   : fs.readFileSync 'keys/server.key'
    cert  : fs.readFileSync 'keys/server.crt'
    ca    : fs.readFileSync 'keys/server.csr'

  spdy.createServer(options, requestHandler(cache))
    .listen config.https_port

startHTTP = () ->
  htmlResp = """
    <html>
    <head><title>301 Moved Permanently</title></head>
    <body bgcolor="white">
    <center><h1>301 Moved Permanently</h1></center>
    </body>
    </html>
  """

  handler = (req, res) ->
    res.writeHead 301,
      "Location": config.uri()
    res.end htmlResp

  http.createServer(handler).listen config.http_port

serveStaticFile = (req, res, file, cache) ->
  headers = req.headers

  fetchContent file, headers, "common", cache,
    (data, respHeaders, code) ->
      if code is 404
        return send404 req, res, cache

      #else if data is null
      #  respHeaders["Content-Length"] = 0
      #else
      #  respHeaders["Content-Length"] = +data.length

      res.writeHead code, respHeaders
      res.end data

requestHandler = (cache) ->
  (req, res) ->
    parsedUrl = url.parse req.url
    subStr = parsedUrl.pathname[1..config.static_dir.length]

    # "/#{subStr}" is "/static"
    if subStr is config.static_dir
      serveStaticFile req, res, parsedUrl.pathname, cache
    else
      eventAggr.emit "HTTP_REQUEST_RECEIVED", req, res, parsedUrl.path
