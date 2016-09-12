{log, createWithPostCreate} = require 'art-foundation'
{missing, Pipeline} = Neptune.Art.Ery

module.exports = suite: ->
  test "basic", ->
    path = ""
    createWithPostCreate class MyPipeline extends Pipeline
      @handlers create: (request) -> foo: 1, bar: 2
      @filter
        after: create: (response) ->
          path += "filter1"
          throw "you lose!"
      @filter
        after: create: (response) ->
          log "shouldn't get here!", response: response
          path += "filter2"
          assert.fail()

    p = new MyPipeline
    assert.rejects p.create()
    .then (v) ->
      assert.eq path, "filter1"
      assert.eq v.error, "you lose!"
