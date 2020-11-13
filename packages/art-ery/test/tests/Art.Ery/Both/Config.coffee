Foundation = require 'art-foundation'
Ery = require('art-ery')
{assert} = require('art-testbench');

{merge, log, createWithPostCreate, CommunicationStatus, wordsArray} = Foundation
{missing} = CommunicationStatus
{Pipeline, Filter, config} = Ery

module.exports =

  suite: ->
    test "config.tableNamePrefix", ->
      config.tableNamePrefix = "AwesomeApp."
      pipeline = new class MyPipeline extends Pipeline
      assert.eq pipeline.tableName, "AwesomeApp.myPipeline"
