# https://developer.mozilla.org/en-US/docs/Web/API/TextMetrics

###
#TODO

refactor to an object you create
if either tight or tight0 are requested, calculate both
for textual, have two areas:
  textualArea - the current area we compute based on font-size and glyph width
  textualDrawArea - a pessimistic, but always true, area that covers all pixels
    since we have no concrete information on this, we'll just make it something like 2x textualArea - or more

###
{floor, ceil} = Math
{
  defineModule, merge, log, logL, inspect
  max, min, isObject, isString, allIndexes, eachMatch, clone
  present
} = require 'art-standard-lib'
{BaseClass} = require 'art-class-system'

{Bitmap} = require '@art-suite/art-canvas'
{point, rect, point0, Rectangle} = require 'art-atomic'

TextLayoutFragment = require './TextLayoutFragment'

defineModule module, ->

  alphaChannelOffset = 3
  pixelStep = 4
  tightThreshold = 127

  class Metrics extends BaseClass
    @defaultFontSizeProportionalDrawAreaPadding: .45
    @tightDrawAreaPadding: 1
    @defaultFontOptions: defaultFontOptions =
      fontStyle   : 'normal'
      fontVariant : 'normal'
      fontWeight  : 'normal'
      fontSize    : 16
      fontFamily  : 'Times'

    @toFontCss: toFontCss = (fontOptions) ->
      "#{fontOptions.fontStyle   || 'normal'}
       #{fontOptions.fontVariant || 'normal'}
       #{fontOptions.fontWeight  || 'normal'}
       #{fontOptions.fontSize    || 16}px
       #{fontOptions.fontFamily  || 'Times'}, Times"

    @normalizeFontOptions: normalizeFontOptions =(fontOptions)->
      fontOptions.fontStyle   ||= defaultFontOptions.fontStyle
      fontOptions.fontVariant ||= defaultFontOptions.fontVariant
      fontOptions.fontWeight  ||= defaultFontOptions.fontWeight
      fontOptions.fontSize    ||= defaultFontOptions.fontSize
      fontOptions.fontFamily  ||= defaultFontOptions.fontFamily
      fontOptions

    # text: required
    # layoutMode: "textual"
    #   "textual" - use the fontSize and character spacing to determine the area - NOT the glyphs
    #   "tight" - find the exact edge of the glyphs by rendering the font and looking for pixels > 50% grey
    #   "tight0" - find the exact edge of the glyphs by rendering the font and looking for pixels > 0% grey
    #     tight0 may be useful if fontSizes are small enough that significant glyph
    #     features are smaller than a 2 pixels, otherwise use "tight"
    #     i.e. Maybe use when fontSize <= 6 and maybe on slightly larger sizes too
    # fontOptions - see css
    # fontOptions must be normalized (use @normalizeFontOptions)
    # fontCss is optional. It should == toFontCss fontOptions
    @get: (text, fontOptions = {}, layoutMode, fontCss) ->

      unless fontOptions.fontSize
        fontOptions = normalizeFontOptions fontOptions

      switch layoutMode
        when null, undefined, "textual" then @_getTextualFontMetrics text, fontOptions, null, fontCss
        when "textualBaseline" then @_getTextualFontMetrics text, fontOptions, null, fontCss, false
        when "tight"   then @_getTightFontMetrics text, 0, fontOptions, fontCss
        when "tight0"  then @_getTightFontMetrics text, 0, fontOptions, fontCss
        else throw new Error "invalid layoutMode: #{inspect layoutMode}"

    @getWidth: (text, fontOptions, fontCss) =>
      context = @getScratchCanvasBitmap().context
      context.font = fontCss || toFontCss fontOptions
      context.measureText(text).width

    @_wrapOnce: (context, text, wordWrapWidth) ->
      return [text, null] if context.measureText(text).width <= wordWrapWidth

    @_noBreaksWrapIndex: noBreaksWrapIndex = (context, text, wordWrapWidth) ->
      left = 0
      leftPixelWidth = 0
      leftSlice = null
      right = text.length
      while right - left > 1
        m = (left + right) / 2 | 0
        if (width = context.measureText(sliced = text.slice 0, m).width) > wordWrapWidth
          right = m
        else
          leftSlice = sliced
          leftPixelWidth = width
          left = m

      unless leftSlice
        leftSlice = text.slice 0, 1
        leftPixelWidth = context.measureText(leftSlice).width

      [leftPixelWidth, leftSlice]

    blankString = ""

    # layoutMode can be 'textual' or 'textualBaseline'
    @wrap: (text, fontOptions, wordWrapWidth, fontCss, layoutMode = "textual") ->
      areaIncludesDescender = layoutMode == "textual"

      return [@_getTextualFontMetrics("", fontOptions, 0, fontCss, areaIncludesDescender)] if text == "" # HACK FIX for blank lines

      wordWrapWidth = 0 if wordWrapWidth < 0

      context = @getScratchCanvasBitmap().context
      context.font = fontCss

      linePixelWidth = 0
      lines = []
      line = blankString
      trailingSpace = blankString
      trailingSpacePixelWidth = 0

      nextLine = =>
        if linePixelWidth > 0
          lines.push @_getTextualFontMetrics line, fontOptions, linePixelWidth, fontCss, areaIncludesDescender
          line = blankString
          linePixelWidth = 0
          trailingSpace = blankString
          trailingSpacePixelWidth = 0

      eachMatch text, /(\s*[^-\s]+-*|\s*-+)(\s*)/g, (result) ->
        wordStart = result.index
        [_, word, space] = result
        wordLength = word.length
        whiteSpaceLength = space.length
        whiteSpacePixelWidth = context.measureText(space).width
        wordPixelWidth = context.measureText(word).width

        if wordPixelWidth > wordWrapWidth
          # single word is too long for line
          # start a new line
          # split word and add new lines as many times as needed so it all fits
          while wordPixelWidth > wordWrapWidth
            nextLine()
            [pixelWidth, firstHalfText] = noBreaksWrapIndex context, word, wordWrapWidth

            line = firstHalfText
            linePixelWidth = pixelWidth

            word = word.slice firstHalfText.length, word.length
            wordPixelWidth = context.measureText(word).width

          nextLine()

          line = word
          linePixelWidth = wordPixelWidth

        else if trailingSpacePixelWidth + linePixelWidth + wordPixelWidth > wordWrapWidth
          # word is too long for the remaining space on current line
          # > start new line with current word
          nextLine()
          line = word
          linePixelWidth = wordPixelWidth
        else
          # have space for word and previous trailing space, add word
          line += trailingSpace + word
          linePixelWidth += trailingSpacePixelWidth + wordPixelWidth

        trailingSpace = space
        trailingSpacePixelWidth = whiteSpacePixelWidth

      nextLine()
      lines[0]?.firstFragment = true
      lines

    ##################
    # PRIVATE
    ##################

    @_tightFontMetricCache: {}

    @_getTightFontMetrics: (text, tightThreshold, fontOptions, fontCss)  ->
      return new TextLayoutFragment text, fontOptions unless present text

      tightFontMetricCacheKey = "#{text}:#{tightThreshold}:#{fontCss ||= toFontCss fontOptions}"
      previousResult = @_tightFontMetricCache[tightFontMetricCacheKey] ||= if text.length <= 3
        upScale = 2
        fontOptions = merge fontOptions, fontSize: fontOptions.fontSize * upScale
        fontCss = toFontCss fontOptions
        @_generateTightFontMetrics(text, tightThreshold, fontOptions, fontCss)
        .mul 1/upScale
      else
        @_generateTightFontMetrics text, tightThreshold, fontOptions, fontCss

      # NOTE!!! We clone the two rectangles so that LAYOUT can modify them.
      #   We allow LAYOUT this dispensation because when using non-cached metrics (non-tight)
      #   it allows us to halve the number of rectangles created.
      previousResult.clone()

    tempRectangleToCapturePessimisticDrawArea = new Rectangle
    minTightRenderFontSize = 32
    @_generateTightFontMetrics: (text, tightThreshold, fontOptions, fontCss)  ->
      {tightDrawAreaPadding} = Metrics
      padding = Metrics.defaultFontSizeProportionalDrawAreaPadding * 2

      {fontSize} = fontOptions
      scale = 1
      if fontSize < minTightRenderFontSize
        scale = fontSize / minTightRenderFontSize
        fontSize = minTightRenderFontSize

      renderFontOptions = if scale != 1
        merge fontOptions, {fontSize}
      else
        fontOptions

      # log _generateTightFontMetrics:padding:padding
      [scratchBitmap, size, location] = @renderTextToScratchBitmap text, renderFontOptions, padding
      data = scratchBitmap.context.getImageData(0, 0, size.x, size.y).data
      # log _generateTightFontMetrics: scratchBitmap, fontOptions:fontOptions

      # getAutoCropRectangle returns the exact bounding rectangle of all pixels >= tightThreshold
      # NOTE: for Atomic.Rectangles, right and bottom are EXCLUSIVE while LEFT and TOP are INCLUSIVE
      {left, right, top, bottom} = scratchBitmap.preciseContentArea

      while left < 1 || top < 1 || right > size.x - 1 || bottom > size.y - 1
        log "Art.Text.Metrics#_generateTightFontMetrics: #{inspect fontOptions, 1}, padding: #{padding} too small. scratchBitmap.size: #{scratchBitmap.size}"
        padding *= 2
        [scratchBitmap, size, location] = @renderTextToScratchBitmap text, renderFontOptions, padding
        {left, right, top, bottom} = scratchBitmap.preciseContentArea

      if scale != 1
        location = location.mul scale
        left *= scale
        right *= scale
        top *= scale
        bottom *= scale

      # adjust top and left so all four point to the first blank column/row

      # alphaFudgeFactor = 1/16
      # left    = max left        | 0, left - alphaFudgeFactor
      # top     = max top         | 0, top - alphaFudgeFactor
      # right   = min right + 1   | 0, right + alphaFudgeFactor
      # bottom  = min bottom + 1  | 0, bottom + alphaFudgeFactor

      textOffsetX = location.x - left
      textOffsetY = location.y - top
      layoutW     = right - left
      layoutH     = bottom - top

      ascender =   location.y - top + 1  # ascender + descender should == area.size.y
      descender =  bottom     - location.y

      # logBitmap = scratchBitmap.clone()
      # logBitmap.drawRectangle null, rect(left/scale, top/scale, layoutW/scale, layoutH/scale),
      #   color: "#f70"
      #   compositeMode: "targetTop"
      # log {
      #   logBitmap
      #   scale, text, fontOptions, ascender
      #   descender, textOffsetX, textOffsetY
      #   layoutW, layoutH, left, right, top, bottom
      #   aspectRatio: layoutW / layoutH
      # }

      new TextLayoutFragment(
        text
        fontOptions
        ascender
        descender
        textOffsetX
        textOffsetY
        layoutW
        layoutH
        -tightDrawAreaPadding
        -tightDrawAreaPadding
        layoutW + tightDrawAreaPadding * 2
        layoutH + tightDrawAreaPadding * 2
      )

    @_getTextualFontMetrics: (text, fontOptions, alreadyComputedTextWidth, fontCss, areaIncludesDescender = true) ->
      fontSize = fontOptions.fontSize - 0
      ascender = .75 * fontSize
      descender = .25 * fontSize
      width = if alreadyComputedTextWidth? then alreadyComputedTextWidth else @getWidth text, fontOptions, fontCss

      area = rect 0, descender - fontSize, width, fontSize - if areaIncludesDescender then 0 else descender
      @pessimisticDrawArea width, fontOptions, tempRectangleToCapturePessimisticDrawArea

      new TextLayoutFragment(
        text
        fontOptions
        ascender
        descender
        -area.x
        -area.y
        area.w
        area.h
        tempRectangleToCapturePessimisticDrawArea.x
        tempRectangleToCapturePessimisticDrawArea.y
        tempRectangleToCapturePessimisticDrawArea.w
        tempRectangleToCapturePessimisticDrawArea.h
      )

    @classGetter
      scratchCanvasBitmap: -> @_scratchCanvasBitmap ||= new Bitmap point(10,10)

    # if you draw the text, with the specified options, at location 0, 0...
    # This function makes a pessimistic, 99%+ correct guess...
    # and returns an integer rectangle covering all pixels the text would touch
    @pessimisticDrawArea: (textWidth, fontOptions, intoRectangle, increasedFontSizeProportionalDrawAreaPadding) ->
      fontSize = fontOptions.fontSize

      padding = fontSize * (increasedFontSizeProportionalDrawAreaPadding or fontOptions.padding or Metrics.defaultFontSizeProportionalDrawAreaPadding)

      # log
      #   padding: padding
      #   textWidth: textWidth
      #   fontSize: fontSize
      #   increasedFontSizeProportionalDrawAreaPadding: increasedFontSizeProportionalDrawAreaPadding
      #   "fontOptions.padding": fontOptions.padding
      #   "Metrics.defaultFontSizeProportionalDrawAreaPadding": Metrics.defaultFontSizeProportionalDrawAreaPadding

      x = Math.floor floatX = -padding
      y = Math.floor floatY = -padding # - fontSize * 3/4
      w = Math.ceil(floatX + textWidth + padding * 2) - x
      h = Math.ceil(floatY + fontSize + padding * 2) - y

      # old
      # x = Math.floor -padding #* .25
      # y = Math.floor -padding
      # w = Math.ceil(x + textWidth + padding * 2) - x
      # h = Math.ceil(y + fontSize + padding * 2) - y

      if intoRectangle
        intoRectangle.x = x
        intoRectangle.y = y
        intoRectangle.w = w
        intoRectangle.h = h
        intoRectangle
      else
        rect x, y, w, h

    @_scratchBitmap = null
    @renderTextToScratchBitmap: (text, fontOptions, padding) ->
      drawArea = @pessimisticDrawArea (@getWidth text, fontOptions), fontOptions, null, padding
      {size} = drawArea.size

      scratchBitmapSize = @_scratchBitmap?.size || point0
      if !scratchBitmapSize.gt size
        @_scratchBitmap = new Bitmap scratchBitmapSize.max size
      else
        @_scratchBitmap.clear() #context.clearRect 0, 0, size.x, size.y

      context = @_scratchBitmap.context
      context.textAlign = 'left'
      context.textBaseline = 'alphabetic'
      context.font = toFontCss fontOptions
      context.fillText text, x = -drawArea.x, y = -drawArea.y + fontOptions.fontSize * 3/4

      # log
      #   renderTextToScratchBitmap: @_scratchBitmap.clone()
      #   font:toFontCss fontOptions
      #   drawArea:drawArea

      [@_scratchBitmap, size,  point x, y]

    @debug: (area, bitmap, location, options) ->
      image = new Bitmap(bitmap.size)
      image.clear "white"
      image.drawRectangle location, area, "#ddf"
      image.drawRectangle location, rect(area.location.x, 0, area.size.x, 1), "red"
      image.drawRectangle location, rect(0, area.location.y, 1, area.size.y), "green"
      image.drawBitmap point(), bitmap
      log image, layoutMode: options.layoutMode
