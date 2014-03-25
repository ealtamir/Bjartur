fs    = require "fs"
zlib  = require "zlib"

config = require("./lib/config").config

exports.fetchContent = (path, headers, cache, callback) ->
  cachedFile = cache.get path

  if headers['if-none-match']? is true
    callback null
  else if headers["accept-encoding"]? is true
    enc = headers["accept-encoding"]
  else
    enc = "raw"

  if enc.indexOf "gzip" >= 0          then enc = "gzip"
  else if enc.indexOf "deflate" >= 0  then enc = "deflate"

  if enc? isnt "raw"
    headers["Content-Encoding"] = enc

  # Must be gzip or deflate
  if cachedFile.data[enc]? is false
    zlib[enc] cachedFile.data["raw"], (error, data) ->
      if error?
        console.log "Error when compressing file."
        process.kill 1

      cachedFile.data[enc] = data
      callback data
  else
    callback cachedFile.data[enc]

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

      else if stats.isDirectory() is true and
      file not in config.staticBlacklist
        newFiles = fs.readdirSync file
        recursiveLoader cache, file, newFiles

      else
        console.log "WARNING: #{file} identified as neither file nor directory."

  return recursiveLoader cache, config.static_dir, files
