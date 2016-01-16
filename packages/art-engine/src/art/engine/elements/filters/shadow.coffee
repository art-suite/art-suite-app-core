define [
  'art.foundation'
  'art.atomic'
  './filter'
], (Foundation, Atomic, Filter) ->
  {createWithPostCreate} = Foundation
  {color, Color, point, Point, rect, Rectangle, matrix, Matrix} = Atomic

  createWithPostCreate class Shadow extends Filter
    constructor: (options = {}) ->
      options.radius = 10 unless options.radius?
      options.compositeMode ||= "destover"
      @inverted = options.inverted
      super

    @drawProperty
      radius:   default: 0, validate: (v) -> typeof v is "number"

    filter: (elementSpaceTarget, scale) ->
      elementSpaceTarget.blurAlpha @_radius * scale, inverted:@inverted
      elementSpaceTarget.drawRectangle null, elementSpaceTarget.size, color:@_color, compositeMode:"target_alphamask"
