Foundation = require 'art-foundation'
{
  lowerCamelCase, wordsArray, isPlainObject, log, compactFlatten
  isString, compactFlatten, deepEachAll, uniqueValues
  isNumber
} = Foundation

TableApiBaseClass = require './TableApiBaseClass'

module.exports = class QueryApi extends TableApiBaseClass

  ###
  IN: params:
    table:                  string (required)
    index:                  string (optional) (sets the indexName)
    limit:                  number (NOTE: DynamoDb returns as many records as match and fit  within 1MB of data, AND, if specified, no more than 'limit' records)
    consistentRead:         true/false(default) (NOTE: not supported on global index queries)
    returnConsumedCapacity: /indexes|total|none/
    descending: true (optional)

    select:                 "*" or "count(*)" (must be exactly these strings)
                            OR a string listing one or more fields
                              Document Paths are supported:
                                http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Expressions.AccessingItemAttributes.html
                              Delimiter:
                                any sequence of 1-or-more non-legal-doc-path-characters is a legal delimiter
                                recommendation: use commas and/or whitespace

                            NOTE: If you want to return a field named '*' or 'count(*)', either request more than one field,
                              or add a space before or after the field-name so it doesn't exactly match one of those strings.
                            Default: DynamoDB defaults to allAttributes when accessing a table, and allProjectedAttributes when accessing an index.

    where:
      # NOTE: this replaces keyConditionExpression and related params
      partitionKeyName: exactEqualValue
      sortKeyName:
        testName: testValue or testValueArray
          # test names:
          eq
          lt
          lte
          gt
          gte
          between  # testValue is a length-2 array [a, b]; returns values >= a and <= b
          beginsWith

      # Examples:
      where: myPartitionKey: "abc123"
      where: myPartitionKey: "abc123", mySortKey: gte: "fooBar"
      where: myPartitionKey: "abc123", mySortKey: gte: "fooBar", descending: true
      where: myPartitionKey: "abc123", mySortKey: between: ["fooBar", "zooBar"]

    startKey:
      # NOTE: this replaces exclusiveStartKey
      # Used to get the next 'page' of records for a given query.
      # "Use the value that was returned for LastEvaluatedKey in the previous operation."

    #------------------
    # TODO
    #------------------
    filterExpression:
      TODO: this will use a simlar pattern to 'where'
      I think we should allow you to just do a normal DynamoDb filterExpression.
      The 'where' pattern is useful when you need to escape things. OH, there are no literals, so you couldn't
      use this if you had any literal value to include.

      This is interesting since I think you can use a doc-path for your value.

      I don't think that is allows for the 'where' syntax anyway, but it definitly is here.
      How do we distinguish between a doc-path and a value???

        gut:
          myField: eq: docPath myOtherField

        Where docPath a function that returns a non-plain object.

      Reference:
        http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Expressions.SpecifyingConditions.html#ConditionExpressionReference
        http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/QueryAndScan.html#FilteringResults

      Idea to support AND, OR and NOT:
        [a, "or", b]
        [a, "and", b]
        ["not", a]
        [a, "or", b, "and", c]

      Ex:
        filterExpression: [
            foo: eq: "foo"
            "or"
            foo: eq: "bar"
          ]
      becomes:
        FilterExpression: 'foo = "foo" OR foo = "bar"'

    #------------------
    # DEPRICATED (by ArtAws) DYNAMODB PARAMS:
    #------------------
      # use: 'select'
      projectionExpression:

      # use: 'where'
      keyConditionExpression
      scanIndexForward
      expressionAttributeNames
      expressionAttributeValues


  ###
  _translateParams: (params) =>
    @_translateOptionalParams params
    @_translateWhere params
    @_target

  #############################
  # PRIVATE
  #############################
  _translateLimit: (params) ->
    @_target.Limit = params.limit if params.limit?

  _translateConsistentRead: (params) ->
    @_target.ConsistentRead = true if params.consistentRead

  _translateExclusiveStartKey: (params) ->
    @_target.ExclusiveStartKey = params.exclusiveStartKey if params.exclusiveStartKey

  _translateDescending: (params) ->
    @_target.ScanIndexForward = true if params.descending

  _translateWhere: (params) ->
    {where} = params
    throw new Error "where param required" unless where?
    @_target.KeyConditionExpression = @_translateConditionExpression where
    @_target

  _translateSelect: (params) ->
    {select} = params
    return @_target unless select
    @_target.Select = switch select
      when "*" then "ALL_ATTRIBUTES"
      when "count(*)" then "COUNT"
      else
        select = select.match /[a-z0-9\[\].]+/gi if isString select
        select.join ', '

    @_target

  _translateOptionalParams: (params) =>
    @_translateIndexName params
    @_translateLimit params
    @_translateConsistentRead params
    @_translateConstantParam params, "returnConsumedCapacity"
    @_translateDescending params
    @_translateExclusiveStartKey params
    @_translateSelect params
    @_target



