
exports.config =
  path404          : "/static/resources/404.html"
  https_port       :  8888
  http_port        :  9999
  static_dir       :  "static"
  domain_name      :  "localhost"

  events : [
    "HTTP_REQUEST_RECEIVED"
  ]

  staticBlacklist  :  [
    "/static/resources"
  ]

  uri              :  () ->
    "https://#{@domain_name}:#{@https_port}"
