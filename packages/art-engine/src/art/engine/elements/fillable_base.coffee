Foundation = require 'art-foundation'
Atomic = require 'art-atomic'
Canvas = require 'art-canvas'
Base = require './base'
{PointLayout, PointLayoutBase} = require '../layout'
{log, isPlainObject, min, max, createWithPostCreate, isNumber, merge} = Foundation
{rgbColor, Color, point, Point, rect, Rectangle, matrix, Matrix, point0, point1} = Atomic
{GradientFillStyle} = Canvas
# can be a gradient fill or a solid-color fill
# if the @gradient property is set (including indirectly by setting the @colors property), then it is a gradient
# Otherwise, the @color property is used and @from and @to properties are ignored.
module.exports = createWithPostCreate class FillableBase extends Base
  @registerWithElementFactory: -> @ != FillableBase

  @getter
    cacheable: -> @getHasChildren()

  defaultFrom = new PointLayout()
  defaultTo = new PointLayout hh: 1
  defaultOffset = new PointLayout y: 2
  noShadow =
    color: rgbColor 0,0,0,0
    blur: 0
    offset: new PointLayout 0
  @drawProperty
    # from:   default: "topLeft", preprocess: (v) -> point v
    # to:     default: null, preprocess: (v) -> v? && point v
    from: preprocess: (v) -> v && if v instanceof PointLayoutBase then v else new PointLayout v
    to:   preprocess: (v) -> v && if v instanceof PointLayoutBase then v else new PointLayout v

    colors: default: null
    gradientRadius: default: null
    shadow:
      default: null
      validate: (v) -> !v || v == true || isPlainObject v
      preprocess: (v) ->
        return noShadow unless v
        {color, offset, blur} = v
        color = rgbColor color || "#0007"
        offset = if offset?
          if offset instanceof PointLayoutBase
            offset
          else
            new PointLayout offset
        else
          defaultOffset

        blur = 4 unless blur?

        blur: blur
        offset: offset
        color: color

  @getter
    normalizedShadow: ->
      return null if @_shadow == noShadow
      {offset} = @_shadow
      x = offset.layoutX @_currentSize
      y = offset.layoutY @_currentSize
      merge @_shadow,
        offsetX: x
        offsetY: y

  _expandRectangleByShadow: (r, shadow) ->
    return r if shadow == noShadow
    {x, y, w, h} = r
    {blur, offsetX, offsetY} = @normalizedShadow
    offsetX ||= 0
    offsetY ||= 0
    blur ||= 0
    expandLeft    = max 0, blur - offsetX
    expandTop     = max 0, blur - offsetY
    expandRight   = max 0, blur + offsetX
    expandBottom  = max 0, blur + offsetY
    r.with(
      x - expandLeft
      y - expandTop
      w + expandLeft + expandRight
      h + expandTop + expandBottom
    )

  @virtualProperty
    baseDrawArea: (pending) ->
      @_expandRectangleByShadow @getPreFilteredBaseDrawArea(pending), @getState(pending)._shadow

  _prepareDrawOptions: (drawOptions, compositeMode, opacity)->
    super
    {_colors, _currentSize} = @

    drawOptions.shadow = @normalizedShadow

    drawOptions.colors = null
    drawOptions.gradientRadius = null
    drawOptions.gradientRadius1 = null
    drawOptions.gradientRadius2 = null
    drawOptions.from = null
    drawOptions.to = null

    if _colors
      {_from, _to, _gradientRadius} = @
      _from ||= defaultFrom

      drawOptions.colors = _colors
      if _gradientRadius?
        _to ||= _from
        gradientScale = _currentSize.min() / 2
        if isNumber _gradientRadius
          drawOptions.gradientRadius = _gradientRadius * gradientScale
        else
          [r1, r2] = _gradientRadius
          drawOptions.gradientRadius1 = r1 * gradientScale
          drawOptions.gradientRadius2 = r2 * gradientScale

      _to ||= defaultTo

      # I don't love this solution to scaling the gradient from/to, but it's acceptable for now.
      # It creates two new objects, which is unfortunate. It also mutates an object which should be immutable.
      drawOptions.from   = _from.layout _currentSize
      drawOptions.to     = _to.layout _currentSize
