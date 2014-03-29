fs    = require "fs"
zlib  = require "zlib"
mime  = require "mime"

config = require("./lib/config").config

getHeaders = (type="common", file, cache) ->
  if type is "common"
    etag = cache.get(file).stats.atime
    return {
      "Date"             : new Date().toString()
      "Cache-Control"    : "max-age=1000000"
      "Content-Type"     : mime.lookup file
      "Etag"             : +etag
    }

  else if type is "error404"
    "Date"           :  new Date().toString()
    "Content-Type"   :  "text/html"
    "Cache-Control"  :  "no-cache"

  else
    console.log "Incorrect headers type."
    process.kill(1)

isValid = (cachedFile, path) ->
  if cachedFile? is false
    return false
  else if path isnt config.path404
    # checks that path or path substr is not in blacklist
    for name in config.staticBlacklist
      if name.length <= path.length and name is path[0...name.length]
        return false
  else
    return true

getEncoding = (headers, respHeaders) ->
  if headers["accept-encoding"]? is true
    enc = headers["accept-encoding"]

    if enc.indexOf "gzip" >= 0
      enc = "gzip"
      respHeaders["Content-Encoding"] = enc
    else if enc.indexOf "deflate" >= 0
      enc = "deflate"
      respHeaders["Content-Encoding"] = enc
  else
    enc = "raw"

  return enc

serveContent = (path, headers, headType, cache,  callback) ->
  cachedFile  = cache.get path
  respHeaders = getHeaders headType, path, cache

  if headers['if-none-match']? is true
    callback null
  else
    enc = getEncoding headers, respHeaders

  # Must be gzip or deflate
  if cachedFile.data[enc]? is false
    zlib[enc] cachedFile.data["raw"], (error, data) ->
      if error?
        console.log "Error at file compression."
        process.kill 1

      cachedFile.data[enc] = data
      callback data, respHeaders, 200
  else
    callback cachedFile.data[enc], respHeaders, 200

exports.fetchResource = (path, headers, headType, cache,  callback) ->
  serveContent path, headers, headType, cache, callback

exports.fetchContent = (path, headers, headType, cache,  callback) ->
  cachedFile = cache.get path

  if isValid(cachedFile, path) is false
    console.log "Caught an unvalid path: #{path}"
    return callback null, null, 404

  serveContent path, headers, headType, cache, callback


exports.send404 = (req, res, cache) ->
  path = config.path404
  headers = req.headers

  exports.fetchContent path, headers, "error404", cache,
    (data, respHeaders, code) ->
      if code is 404
        console.log "Stuck on sending 404 response. Infinite recursive calls."
        process.kill(1)

      res.writeHead 404, respHeaders
      res.end data

exports.loadStaticFiles = (cache) ->
  files = fs.readdirSync config.static_dir

  recursiveLoader = (cache, prefix, files) ->
    if files.length is 0
      return false

    prefix or= ""

    files.forEach (file) ->
      file = "#{prefix}/#{file}"

      stats = fs.statSync file

      if stats.isFile() is true
        console.log "Loading #{file}"
        cache.put "/#{file}",
          data:
            raw: fs.readFileSync file
          stats: stats

      else if stats.isDirectory() is true
        newFiles = fs.readdirSync file
        recursiveLoader cache, file, newFiles

      else
        console.log "WARNING: #{file} identified as neither file nor directory."

  return recursiveLoader cache, config.static_dir, files
