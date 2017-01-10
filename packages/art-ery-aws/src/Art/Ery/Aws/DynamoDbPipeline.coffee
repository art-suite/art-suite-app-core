Uuid = require 'uuid'

Foundation = require 'art-foundation'
ArtEry = require 'art-ery'
ArtAws = require 'art-aws'

{object, isPlainObject, inspect, log, merge, compare, Validator, isString, arrayToTruthMap, isFunction, withSort} = Foundation
{Pipeline} = ArtEry
{DynamoDb} = ArtAws
{encodeDynamoData, decodeDynamoData} = DynamoDb

module.exports = class DynamoDbPipeline extends Pipeline
  @classGetter
    tablesByNameForVivification: ->
      @_tablesByNameForVivificationPromise ||=
        @getDynamoDb().listTables().then ({TableNames}) =>
          arrayToTruthMap TableNames

    dynamoDb: -> DynamoDb.singleton

  @firstAbstractAncestor: @

  @createTablesForAllRegisteredPipelines: ->
    promises = for name, pipeline of ArtEry.pipelines when isFunction pipeline.createTable
      pipeline.createTable()
    Promise.all promises

  @_primaryKey: "id"
  @primaryKey: (@_primaryKey) ->

  @globalIndexes: (globalIndexes) ->
    @_globalIndexes = globalIndexes
    @query @_getAutoDefinedQueries globalIndexes

  @localIndexes: (localIndexes) ->
    @_localIndexes = localIndexes
    @query @_getAutoDefinedQueries localIndexes

  @getter
    globalIndexes: -> @_options.globalIndexes || @class._globalIndexes
    localIndexes: -> @_options.localIndexes || @class._localIndexes
    primaryKey:    -> @class._primaryKey
    status: ->
      @_vivifyTable()
      .then -> "OK: table exists and is reachable"
      .catch -> "ERROR: could not connect to the table"



  @_getAutoDefinedQueries: (indexes) ->
    return {} unless indexes
    queries = {}

    for queryModelName, indexKey of indexes when isString indexKey
      do (queryModelName, indexKey) =>
        [hashKey, sortKey] = indexKey.split "/"
        whereClause = {}
        queries[queryModelName] =
          query: (request) ->
            whereClause[hashKey] = request.key
            request.pipeline.queryDynamoDb
              index: queryModelName
              where: whereClause
            .then ({items}) -> items

          queryKeyFromRecord: (data) ->
            # log queryKeyFromRecord: data: data, hashKey: hashKey, value: data[hashKey]
            data[hashKey]

          localSort: (queryData) -> withSort queryData, (a, b) ->
            if 0 == ret = compare a[sortKey], b[sortKey]
              compare a.id, b.id
            else
              ret


    queries

  constructor: ->
    super
    @primaryKeyFields = @primaryKey.split "/"

  @getter
    dynamoDb: -> DynamoDb.singleton
    tablesByNameForVivification: -> DynamoDbPipeline.getTablesByNameForVivification()

  ###
  TODO:
  Add to ArtAws.DynamoDb:
    getKeyFromDataFunction: (createTableParams) -> (data) -> key
      IN: createTableParams
        The exact same params used to create the table.
      OUT: (data) -> key
        IN: data: plain object record data
        OUT: key: string which encodes the key
          if there is no range-key, then just returns the hashKey as a string
          else, "#{hashKey}/#{rangeKey}"

    Initially, though, I expect all tables to have a simple hashKey: 'id'
    Indexes will take care of most our rangeKey needs.
  ###

  queryDynamoDb: (params) ->
    @dynamoDb.query merge params, table: @tableName

  scanDynamoDb: (params) ->
    @dynamoDb.scan merge params, table: @tableName

  updateItem: (params) ->
    @dynamoDb.updateItem merge params, table: @tableName

  withDynamoDb: (action, params) ->
    @dynamoDb[action] merge params, table: @tableName

  @dynamoDbKeyFromRequest: (request) ->
    {key} = request
    if isPlainObject key
      key
    else if @primaryKeyFields.length > 1
      object @primaryKeyFields
    else isString key
      id: key
    else
      throw new Error "DynamoDbPipeline: key must be a string. key = #{inspect key}" unless isString key

  @handlers
    get: (request) ->
      @dynamoDb.getItem
        table:  @tableName
        key:    @dynamoDbKeyFromRequest request
      .then (result) ->
        if result.item
          result.item
        else
          request.missing()

    createTable: ->
      @_vivifyTable()
      .then -> message: "success"

    create: ({data}) ->
      throw new Error "DynamoDbPipeline#create: data must be an object. data = #{inspect data}" unless isPlainObject data
      @dynamoDb.putItem
        table:  @tableName
        item:   data
      .then -> data

    update: (request) ->
      {data} = request
      throw new Error "DynamoDbPipeline#update: data must be an object. data = #{inspect data}" unless isPlainObject data
      @dynamoDb.updateItem
        table:  @tableName
        key:    @dynamoDbKeyFromRequest request
        item:   data
      .then ({item}) -> item

    delete: (request) ->
      @dynamoDb.deleteItem
        table:  @tableName
        key:    @dynamoDbKeyFromRequest request
      .then -> message: "success"

  #########################
  # PRIVATE
  #########################

  _vivifyTable: ->
    @_vivifyTablePromise ||= Promise.resolve().then =>
      @tablesByNameForVivification
      .then (tablesByName) =>
        unless tablesByName[@tableName]
          log "#{@getClassName()}#_vivifyTable() dynamoDb table does not exist: #{@tableName}, creating..."
          @_createTable()


  @getter
    dynamoDbCreationAttributes: ->
      out = {}
      for k, v of @normalizedFields
        if v.dataType == "string" || v.dataType == "number"
          out[k] = v.dataType
      out

    streamlinedCreateTableParams: ->
      merge
        table: @tableName
        globalIndexes: @globalIndexes
        localIndexes: @localIndexes
        attributes: @dynamoDbCreationAttributes
        (key: @primaryKey if @primaryKey)
        @_options

    createTableParams: ->
      ArtAws.StreamlinedDynamoDbApi.CreateTable.translateParams @streamlinedCreateTableParams

  _createTable: ->

    @dynamoDb.createTable @streamlinedCreateTableParams
    .catch (e) =>
      log "DynamoDbPipeline#_createTable #{@tableName} FAILED", e
      throw e


