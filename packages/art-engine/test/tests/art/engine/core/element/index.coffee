# generated by Neptune Namespaces
# file: tests/art/engine/core/element/index.coffee

module.exports =
Element           = require './namespace'
Element.Basics    = require './basics'
Element.CacheDraw = require './cache_draw'
Element.Drawing   = require './drawing'
Element.finishLoad(
  ["Basics","CacheDraw","Drawing"]
)