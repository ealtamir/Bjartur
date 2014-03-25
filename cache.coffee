
exports.cache = do () ->
  obj = {}

  obj.put = (key, val) ->
    obj[key] = val

  obj.get = (key) ->
    obj[key]

  return obj
