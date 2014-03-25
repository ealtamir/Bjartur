url   = require "url"
spdy  = require "spdy"
fs    = require "fs"
http  = require "http"
mime = require "mime"

config        =  require("./lib/config").config
cache         =  require("./cache").cache
fetchContent  =  require("./static_content_provider").fetchContent
eventAggr     =  require("./event_aggregator").eventAggregator

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
  etag = cache.get(file).stats.atime

  fetchContent file, headers, cache, (data) ->
    respHeaders =
      "Date"             : new Date().toString()
      "Cache-Control"    : "max-age=1000000"
      "Content-Type"     : mime.lookup file
      "Etag"             : +etag
      "Content-Encoding" : headers["Content-Encoding"] or ''

    if data is null
      respHeaders["Content-Length"] = 0
    else
      respHeaders["Content-Length"] = +data.length

    res.writeHead 200, respHeaders
    res.end data

requestHandler = (cache) ->
  (req, res) ->
    parsedUrl = url.parse req.url
    subStr = parsedUrl.pathname[1..config.static_dir.length]

    # "/#{subStr}" is "/static"
    if subStr is config.static_dir and cache.get(parsedUrl.pathname)?
      serveStaticFile req, res, parsedUrl.pathname, cache
    else
      res.end "Hello World!"
      eventAggr.emit "HANDLE_HTTP_REQUEST", req, res, parsedUrl
