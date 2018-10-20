Foundation  = require 'art-foundation'
Atomic      = require './namespace' # required so we can break the circular dependency between Matrix and Rectangle
AtomicBase  = require './base'
Point       = require './point'

{
  max, min, bound,
  round, floatEq, floor, ceil, round, log,
  isNumber, isArray, isString, isFunction
  stringToNumberArray
  floatEq0
  float32Precision
} = Foundation
{point, isPoint} = Point

# Rectangle supported constructor input signatures:
# (string / toString[able]) -> split on ',' and converted to numbers, then interperted as arguments
# (array) -> reinterpreted as arguments
# arguments:
#   0 arguments:         ()                -> (0, 0, 0, 0)
#   1 point argument:    (size)            -> (0, 0, size.x, size.y)
#   2 point arguments:   (location, size)  -> (location.x, location.y, size.x, size.y)
#   1 number argument:   (s)               -> (0, 0, s, s)
#   2 number argument:   (w, h)            -> (0, 0, w, h)
#   4 number arguments:  (x, y, w, h)
module.exports = class Rectangle extends AtomicBase
  @defineAtomicClass fieldNames: "x y w h", constructorFunctionName: "rect"
  @isRect: isRect = (v) -> v?.constructor == Rectangle

  @rect: rect = (a, b, c, d) ->
    return a if isRect a
    new Rectangle a, b, c, d

  _init: (a, b, c, d) ->
    @x = @y = @w = @h = 0 # ensure consistent object construction
    if d?
      @x = a - 0
      @y = b - 0
      @w = c - 0
      @h = d - 0
    else if b?
      if isPoint b
        @x = a.x
        @y = a.y
        @w = b.w
        @h = b.h
      else
        @w = a - 0
        @h = b - 0
    else if isPoint a
      @w = a.w
      @h = a.h
    else if a?
      @w = @h = a - 0

  @getter
    aspectRatio: -> @w / @h
    location: -> new Point @x, @y
    locationMatrix: -> Atomic.Matrix.translateXY @x, @y
    size: -> new Point @w, @h
    # x: -> @x
    # y: -> @y
    # w: -> @w
    # h: -> @h
    width:  -> @w
    height: -> @h
    rounded: -> @with(
      round @x
      round @y
      round @w
      round @h
    )

    # abbreviated corner names
    tl: -> new Point @x,        @y
    tc: -> new Point @hCenter,  @y
    tr: -> new Point @right,    @y
    lc: -> new Point @x,        @vCenter
    cc: -> new Point @hCenter,  @vCenter
    rc: -> new Point @right,    @vCenter
    bl: -> new Point @x,        @bottom
    bc: -> new Point @hCenter,  @bottom
    br: -> new Point @right,    @bottom

    # full corner names
    topLeft:      -> new Point @x,        @y
    topCenter:    -> new Point @hCenter,  @y
    topRight:     -> new Point @right,    @y
    centerLeft:   -> new Point @x,        @vCenter
    centerCenter: -> new Point @hCenter,  @vCenter
    centerRight:  -> new Point @right,    @vCenter
    bottomLeft:   -> new Point @x,        @bottom
    bottomCenter: -> new Point @hCenter,  @bottom
    bottomRight:  -> new Point @right,    @bottom

    locationIsZero: -> floatEq(@x, 0) && floatEq(@y, 0)
    top: -> @y
    left: -> @x
    right: -> @x + @w
    bottom: -> @y + @h
    hCenter: -> @x + @w *.5
    vCenter: -> @y + @h *.5
    infinite: -> @w == Infinity || @h == Infinity
    normalized: ->
      w = @w
      h = @h
      if w >= 0 && h >= 0
        @
      else
        x = @x
        y = @y
        if w < 0
          x += w
          w = -w
        if h < 0
          y += h
          h = -h
        @with x, y, w, h

    area: -> @w * @h

    # all four points in this order: tl, tr, br, bl
    # order was picked to make drawing paths easy
    corners: ->
      left = @left
      top = @top
      right = @right
      bottom = @bottom
      [
        new Point left, top
        new Point right, top
        new Point right, bottom
        new Point left, bottom
      ]

  # use .with* to only create a new rectangle if values actually changed
  withXY: (x, y)      -> if floatEq(x, @x) && floatEq(y, @y) then @ else new Rectangle x, y, @w, @h
  withWH: (w, h)      -> if floatEq(w, @w) && floatEq(h, @h) then @ else new Rectangle @x, @y, w, h
  withLocation: (v)   -> @withXY v.x, v.y
  withSize:     (v)   -> @withWH v.x, v.y

  movedBy: (d) -> @withXY @x + d.x, @y + d.y

  nearestInsidePoint: (p) -> new Point bound(@left, p.x, @right), bound(@top, p.y, @bottom)
  largestInsideRect: (ofSize) -> # result is centered
    scaler = min @w / ofSize.w, @h / ofSize.h
    w = ofSize.w * scale
    h = ofSize.h * scale
    new Rectangle (@w - w)/2, (@h - h)/2, w, h

  overlaps: (val) ->
    return false unless val?
    if isPoint val then @contains val
    else if isRect val
      val.getRight()   > @getLeft()  &&
      val.getBottom()  > @getTop()   &&
      val.getLeft()    < @getRight() &&
      val.getTop()     < @getBottom()
    else throw new Error("Invalid arguments for 'overlaps'. Expecting Point or Rectangle. Got: #{val}.")

  contains: (val) ->
    return false unless val?
    if isPoint val
      val.x >= @x &&
      val.y >= @y &&
      val.x < @right &&
      val.y < @bottom
    else if isRect val
      val.x >= @x &&
      val.y >= @y &&
      val.right <= @right &&
      val.bottom <= @bottom
    else throw new Error("Invalid arguments for 'contains'. Expecting Point or Rectangle. Got: #{val}.")

  # round the rectangle edges to multiples of m
  round: (m = 1)->
    x = round @x, m
    y = round @y, m
    w = round(@x + @w, m) - x
    h = round(@y + @h, m) - y
    @with x, y, w, h

  # if edges are within k of a multiple of m, round to that multiple
  # Otherwise, round towards the nearest multiple of m that is just outside the original rectangle
  # IN: roundingFactor = if a value is with roundingFactor of a whole number, it will snap that number
  roundOut: (m = 1, k = float32Precision)->
    x = floor @x + k, m
    y = floor @y + k, m
    w = ceil(@x + @w - k, m) - x
    h = ceil(@y + @h - k, m) - y
    @with x, y, w, h

  # if edges are within k of a multiple of m, round to that multiple
  # Otherwise, round towards the nearest multiple of m that is within the original rectangle
  roundIn: (m = 1, k = float32Precision)->
    x = ceil @x - k, m
    y = ceil @y - k, m
    w = floor(@x + @w + k, m) - x
    h = floor(@y + @h + k, m) - y
    @with x, y, w, h

  union: (b) ->
    return @ unless b?
    return b if @getArea() <= 0
    x = min @x, b.left
    y = min @y, b.top
    w = max(@getRight(),  b.getRight() ) - x
    h = max(@getBottom(), b.getBottom()) - y
    @with x, y, w, h

  unionInto: (into) ->
    return new Rectangle @x, @y, @w, @h unless into?
    area = @getArea()
    intoArea = into.getArea()

    return into if area <= 0 || intoArea == Infinity

    if intoArea <= 0 || area == Infinity
      into._setAll @x, @y, @w, @h
    else
      {x, y, w, h} = into
      into._setAll(
        _x = min x, @x
        _y = min y, @y
        max(x + w, @x + @w) - _x
        max(y + h, @y + @h) - _y
      )
    into


  _saveInto = (into, x, y, w, h) ->

    if into
      into._setAll x, y, w, h
    else
      new Rectangle x, y, w, h

  _returnOrSaveInto = (returnThisUnlessInto, into) ->
    if into
      {x, y, w, h} = returnThisUnlessInto
    else
      return returnThisUnlessInto

    _saveInto into, x, y, w, h

  @intersect: intersect = (fromX, fromY, fromW, fromH, withRect, into) ->
    area = fromW * fromH
    intoArea = withRect?.getArea() ? Infinity


    if intoArea <= 0 || area == Infinity
      _returnOrSaveInto withRect, into

    else
      if area <= 0 || intoArea == Infinity
        _saveInto into, fromX, fromY, fromW, fromH

      else
        {x, y, w, h} = withRect
        _saveInto(
          into
          _x = max x, fromX
          _y = max y, fromY
          max 0, min(x + w, fromX + fromW) - _x
          max 0, min(y + h, fromY + fromH) - _y
        )

  intersectInto: (into) -> intersect @x, @y, @w, @h, into, into
  intersect: (withRect, into) -> intersect @x, @y, @w, @h, withRect, into

  intersection: (b) ->
    return @ unless b?
    return @ if b.getArea() == Infinity || b.contains @
    return b if @getArea() == Infinity || @.contains b
    x = max @x, b.left
    y = max @y, b.top
    w = min(@getRight(),  b.getRight() ) - x
    h = min(@getBottom(), b.getBottom()) - y

    if w <= 0 || h <= 0
      Rectangle.nothing
    else
      @with x, y, w, h

  grow: (a, b) ->
    if isPoint a
      {x, y} = a
    else
      x = a
      y = if b? then b else a
    return @ if floatEq0(x) && floatEq0(y)
    @with @x - x, @y - y, @w + 2 * x, @h + 2 * y

  pad: (a) ->
    @grow -a

  # Common instances
  @nothing:     (new Rectangle 0, 0, 0, 0).freeze()
  @everything:  (new Rectangle 0, 0, Infinity, Infinity).freeze()

  withRect: (a,b,c,d) -> @with a,b,c,d

  # return an array of rectangles of what remains when we cut out "r" from this rectangle
  cutout: (r) ->
    return [@] unless @overlaps r
    {x, y, w, h, right, bottom} = @
    out = []
    if r.x > x
      # left column
      out.push new Rectangle x, y, r.x - x, h

    if (rRight = r.right) < right
      # right column
      out.push new Rectangle rRight, y, right - rRight, h

    if r.y > y
      # area above r
      out.push new Rectangle(
        outX = max r.x, x
        y,
        min(rRight, right) - outX
        r.y - y
      )

    if (rBottom = r.bottom) < bottom
      # area below r
      out.push new Rectangle(
        outX = max r.x, x
        rBottom,
        min(rRight, right) - outX
        bottom - rBottom
      )

    out
