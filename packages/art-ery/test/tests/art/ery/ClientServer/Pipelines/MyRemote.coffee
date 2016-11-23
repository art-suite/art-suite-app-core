{defineModule, log} = require 'art-foundation'
{Pipeline} = require 'art-ery'

defineModule module, class MyRemote extends Pipeline

  @remoteServer "http://localhost:8085"

  @filter
    name: "handleByFilter"
    before: handledByFilterRequest: (request) -> request.success()

  @handlers
    get: ({key, data}) -> "#{data?.greeting || 'Hello'} #{key || 'World'}!"

    missing: (request) -> request.missing()

    handledByFilterRequest: ->