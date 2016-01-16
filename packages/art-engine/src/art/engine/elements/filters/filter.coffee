define [
  'art.foundation'
  'art.atomic'
  '../base'
], (Foundation, Atomic, CoreElementsBase) ->
  {log, isString, createWithPostCreate} = Foundation
  {color, Color, point, Point, rect, Rectangle, matrix, Matrix} = Atomic

  ###
  A Filter is any Element with a draw method that takes uses "target's" pixels as input to its own draw computations.

  Ex: Blur and Shadow

  TODO - Fully implelement Blur and Shadow's new semantics:

    Each has a sourceArea, in parent-space, default: rect @parent.size
  ###
  createWithPostCreate class Filter extends CoreElementsBase
    @registerWithElementFactory: -> @ != Filter

    @virtualProperty
      baseDrawArea:
        getter: (o) -> rect(o._currentSize).grow o._radius

    @drawProperty parentSourceArea: default: null, preprocess: (v) -> if v then rect v else null
    @drawAreaProperty radius: default: 0, validate: (v) -> typeof v is "number"

    @getter
      requiresParentStagingBitmap: -> true
      isFilter: -> true
      # don't override, set @_parentSourceArea instead
      parentSourceLocation: -> @_parentSourceArea?.location || point()
      parentSourceSize: -> @_parentSourceArea?.getSize() || @parent?.getCurrentSize()
      parentSourceArea: -> @_parentSourceArea || (@parent && rect @parent.getCurrentSize())


    parentToElementDrawSpaceMatrix: (scale)->
      m = Matrix.scale(@_currentSize.mul(scale).div @parentSourceSize)
      m = m.translate(@radius * scale)
      if @_parentSourceArea
        Matrix.translate(@parentSourceLocation.neg).mul m
      else
        m

    elementAreaToParentSourceArea: (r)->
      if @_parentSourceArea
        psa = @_parentSourceArea
        sx = psa.w / @_currentSize.x
        sy = psa.h / @_currentSize.y
        rect -psa.x, -psa.y, sx * r.w, sy * r.h
      else
        # for the default parentSourceArea, this is just an identity-function
        r

    overDraw: (proposedTargetSpaceDrawArea, parentToTargetMatrix) ->
      targetToElementMatrix = parentToTargetMatrix.inv.mul @parentToElementMatrix
      propsedElementSpaceDrawArea = targetToElementMatrix.transformBoundingRect proposedTargetSpaceDrawArea
      minimumElementSpaceDrawArea = propsedElementSpaceDrawArea.grow(@radius).intersection @elementSpaceDrawArea
      requiredTargetSpaceDrawArea = parentToTargetMatrix.transformBoundingRect @elementAreaToParentSourceArea minimumElementSpaceDrawArea
      proposedTargetSpaceDrawArea.union requiredTargetSpaceDrawArea

    # override this for the "simplest" filter control
    # pixelData is an array of RGBA values. There are @_currentSize.x * 4 numbers per row, and @_currentSize.y rows
    # Convert x, y coordinates to array index:
    #   (x, y) -> (@_currentSize.x * y + x) * 4
    filterPixelData: (elementSpaceTarget, pixelData, scale) ->
      pixelData

    # override this for "normal" filter control. Replace elementSpaceTarget with the new filtered data.
    # return bitmap of the same size as elementSpaceTarget (optionally elementSpaceTarget, optionally altered)
    filter: (elementSpaceTarget, scale) ->
      imageData = elementSpaceTarget.getImageData()
      @filterPixelData elementSpaceTarget, imageData.data, scale
      elementSpaceTarget.putImageData imageData
      elementSpaceTarget

    @drawProperty
      filterSource: default: null,  validate:   (v) -> !v || isString v

    @getter
      filterSourceElement: ->
        filterSource = @getFilterSource()
        if filterSource
          p = @getParent()
          while p && p.name != filterSource
            p = p.getParent()
          if p
            return p
          else
            console.warn "#{@inspectedName}: no ancestor's name matches filterSource:#{inspect filterSource}"
        @getParent()

    drawBasic: (target, elementToTargetMatrix, compositeMode, opacity) ->
      filterSource = @getFilterSourceElement()

      elementSpaceDrawArea = @elementSpaceDrawArea
      scale = elementToTargetMatrix.exactScaler

      filterScratch = @bitmapFactory.newBitmap elementSpaceDrawArea.size.mul scale

      clipRect = rect -elementSpaceDrawArea.x * scale, -elementSpaceDrawArea.y * scale, @_currentSize.x * scale, @_currentSize.y * scale
      filterScratch.clippedTo clipRect, =>
        targetToParentMatrix = filterSource._currentToTargetMatrix.inv
        drawMatrix = targetToParentMatrix.mul @parentToElementDrawSpaceMatrix scale
        filterScratch.drawBitmap drawMatrix, filterSource._currentDrawTarget

      filterScratch = @filter filterScratch, scale

      m = Matrix.scale(1/scale).translate(-@radius).mul elementToTargetMatrix
      target.drawBitmap m, filterScratch, compositeMode:compositeMode, opacity:opacity

