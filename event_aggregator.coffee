events = require "events"
util = require "util"

exports.eventAggregator = do () ->
  # Singleton class
  class EventAggregator
    constructor: () ->
      null

  util.inherits EventAggregator, events.EventEmitter

  eventAggr = new EventAggregator()
