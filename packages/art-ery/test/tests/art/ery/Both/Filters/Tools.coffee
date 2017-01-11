{array, log, createWithPostCreate, w, isString, Validator, w} = require 'art-foundation'
{createDatabaseFilters} = Neptune.Art.Ery.Filters
SimplePipeline = require '../SimplePipeline'

module.exports = suite: createDatabaseFilters: ->
  setup ->
    Neptune.Art.Ery.config.location = "both"


  teardown ->
    Neptune.Art.Ery.config.location = "client"

  test "fields are set correctly", ->
    {myPipeline} = createWithPostCreate class MyPipeline extends SimplePipeline
      @filter createDatabaseFilters
        user:   "required link"
        foo:    link: true, required: true
        bar:    link: "user"
        message: "present trimmedString"

    assert.eq Object.keys(myPipeline.fields), w "
      id
      createdAt
      updatedAt
      userId
      fooId
      barId
      message
      "

    assert.eq (array myPipeline.filters, (v) -> v.name), w "
      UniqueIdFilter
      TimestampFilter
      LinkFieldsFilter
      ValidationFilter
      "

  test "create", ->
    createWithPostCreate class MyPipeline extends SimplePipeline
      @filter createDatabaseFilters
        user: required: link: "user"
        message: "present trimmedString"

    MyPipeline.singleton.create
      data:
        user: id: "abc123", name: "George"
        message: "Hi!"
    .then (data) ->
      assert.eq data.message, "Hi!"
      assert.eq data.userId, "abc123"
      assert.isNumber data.createdAt
      assert.isNumber data.updatedAt
      assert.match data.id, /^[-_a-zA-Z0-9\/\:]{12}$/

  test "userOwned only field", ->
    {myPipeline} = createWithPostCreate class MyPipeline extends SimplePipeline
      @filter createDatabaseFilters
        userOwned: true

    assert.eq Object.keys(myPipeline.fields), w "
      id
      createdAt
      updatedAt
      userId
      "

    assert.eq (array myPipeline.filters, (v) -> v.name), w "
      UniqueIdFilter
      TimestampFilter
      LinkFieldsFilter
      UserOwnedFilter
      "

  test "userOwned and another field", ->
    {myPipeline} = createWithPostCreate class MyPipeline extends SimplePipeline
      @filter createDatabaseFilters
        userOwned: true
        myField: "strings"

    assert.eq Object.keys(myPipeline.fields), w "
      id
      createdAt
      updatedAt
      userId
      myField
      "

    assert.eq (array myPipeline.filters, (v) -> v.name), w "
      UniqueIdFilter
      TimestampFilter
      LinkFieldsFilter
      UserOwnedFilter
      ValidationFilter
      "
