
exports.config =
  https_port       :  8888
  http_port        :  9999
  static_dir       :  "static"
  staticBlackList  :  [
  ]
  domain_name      :  "localhost"
  uri              :  () ->
    "https://#{@domain_name}:#{@https_port}"
