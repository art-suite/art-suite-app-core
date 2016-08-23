Foundation = require 'art-foundation'
{
  lowerCamelCase, wordsArray, isPlainObject, log, compactFlatten
  isString, compactFlatten, deepEachAll, uniqueValues
  isNumber
} = Foundation

TableApiBaseClass = require './TableApiBaseClass'

module.exports = class PutItemApi extends TableApiBaseClass
  ###
  IN: params:
    table:                  string (required)

  ###
  _translateParams: (params) =>
    @_translateItem params
    @_translateOptionalParams params
    @_target

  _translateItem: (params) =>
    {item} = params
    throw new Error "item required" unless item
    @_target.Item = @_encodeItem item
    @_target

  _translateConditionExpression: (params) ->
    {conditionalExpression} = params
    return @_target unless conditionalExpression
    @_target.ConditionalExpression = @_translateConditionExpression conditionalExpression
    @_target

  ReturnConsumedCapacity: 'INDEXES | TOTAL | NONE',
  ReturnItemCollectionMetrics: 'SIZE | NONE',
  ReturnValues: 'NONE | ALL_OLD | UPDATED_OLD | ALL_NEW | UPDATED_NEW'

  _translateOptionalParams: (params) ->
    @_translateConstantParam params, "returnConsumedCapacity"
    @_translateConstantParam params, "returnItemCollectionMetrics"
    @_translateConstantParam params, "returnConsumedCapacity"
