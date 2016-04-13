Foundation = require 'art-foundation'
Atomic = require 'art-atomic'
Engine = require 'art-engine'
Helper = require '../helper'

{insepct, log} = Foundation
{point, rect, Matrix, matrix} = Atomic
{FillElement, ShadowElement, RectangleElement, OutlineElement, Element, TextElement} = Engine
{drawTest, drawTest2, drawTest3} = Helper

suite "Art.Engine.Elements.Filters.ShadowElement.basics", ->
  drawTest3 "basic",
    stagingBitmapsCreateShouldBe: 1
    element: ->
      new RectangleElement color:"red", size:point(80, 60),
        new FillElement
        new ShadowElement radius: 10, location: 10

  drawTest3 "shadow shadow",
    stagingBitmapsCreateShouldBe: 1
    elementSpaceDrawAreaShouldBe: rect 0, 0, 110, 90
    element: ->
      new RectangleElement color: "red", size: point(80, 60),
        new FillElement
        new ShadowElement key:"shadow1", radius: 0, color: "orange", location: 10
        new ShadowElement
          key:"shadow2"
          # size: ps:1, w:10, h:10
          location: 10
          parentSourceArea: point 90, 70
          radius: 10

  drawTest3 "non-standard size with base source draw-area",
    stagingBitmapsCreateShouldBe: 1
    elementSpaceDrawAreaShouldBe: rect 0, 0, 120, 100
    element: ->
      new RectangleElement color: "red", size: point(80, 60),
        new FillElement
        new ShadowElement
          key:"shadow2"
          size: ps:1, plus:20
          location: 10
          parentSourceArea: point 90, 70
          radius: 10

  drawTest3 "non-standard size with expanded source draw-area",
    stagingBitmapsCreateShouldBe: 1
    elementSpaceDrawAreaShouldBe: rect -10, -16, 170, 140
    element: ->
      new RectangleElement color: "red", size: point(80, 60),
        new FillElement
        new FillElement location: x:-8, y:-12
        new FillElement location: x:32, y:18
        new ShadowElement
          key:"shadow2"
          size: ps:1, plus:20
          location: 10
          parentSourceArea: point 90, 70
          radius: 10

  drawTest3 "outline shadow",
    stagingBitmapsCreateShouldBe: 1
    elementSpaceDrawAreaShouldBe: rect -10, -10, 120, 100
    element: ->
      new RectangleElement color:"red", size:point(90, 70),
        new FillElement
        new OutlineElement
          color: "orange"
          lineWidth: 10
          lineJoin: "round"
          compositeMode: "destOver"
        new ShadowElement
          radius:10
          parentSourceArea: rect -5, -5, 90, 70
          location: 5
          size: w:90, h:70


  drawTest2 "parent overdraw required", ->
    new RectangleElement color:"red", size:point(80, 60), location: point(-100, -20),
      new FillElement
      new ShadowElement radius:10, location:point 10

  drawTest2 "gradient child filterSource", ->
    new RectangleElement
      color:          "red"
      size:           point(80, 60)
      radius:         50
      name:           "myFilterSource"
      new FillElement
      new Element
        location: 10
        compositeMode: "destOver"
        new RectangleElement
          size: plus:20, ps:1
          location: -10
          colors: [
            "#f0f", "#ff0"
            "#f0f", "#ff0"
            "#f0f", "#ff0"
            "#f0f", "#ff0"
            "#f0f", "#ff0"
          ]
        new ShadowElement
          radius: 4
          isMask: true
          filterSource: "myFilterSource"

  drawTest3 "opacity 50%",
    element: ->
      new RectangleElement color:"red", size:point(80, 60),
        new FillElement
        new ShadowElement radius:10, opacity:.5, location:point 10

  drawTest2 "sourcein", ->
    new RectangleElement color:"red", size:point(80, 60),
      new FillElement
      new ShadowElement radius:10, compositeMode:"sourcein", location:point 10

  drawTest2 "with 50% scaled drawMatrix", ->
    new RectangleElement color:"red", size:point(80, 60), scale:point(.5),
      new FillElement
      new ShadowElement radius:10, location:point 10

  drawTest2 "parent rotated 180deg - shadow should be to the upper-left", ->
    new RectangleElement color:"red", size:point(80, 60), axis:.5, location:point(50,30), angle:Math.PI,
      new FillElement
      new ShadowElement radius:10, location:point 10

  drawTest2 "parent rotated 45deg - shadow should offset directly down", ->
    new RectangleElement color:"red", size:point(80, 60), axis:.5, location:point(50,30), angle:Math.PI/4,
      new FillElement
      new ShadowElement radius:10, location:point 10

  drawTest2 "shadow rotated 60deg", ->
    new RectangleElement color:"red", size:point(80, 60),
      new FillElement
      new ShadowElement radius:10, axis:.5, angle:Math.PI/3, location: wpw:.5, hph:.5, x:10, y:10

  drawTest3 "child of TextElement basic",
    stagingBitmapsCreateShouldBe: 1
    element: ->
      new TextElement fontFamily:"impact", fontSize:80, text:"TextElement",
        new FillElement color: "red"
        new ShadowElement radius:10, location:10

  drawTest3 "child of TextElement gradient",
    stagingBitmapsCreateShouldBe: 3
    element: ->
      new TextElement
        fontFamily:     "impact"
        fontSize:       80
        text:           "TextElement"
        name: "myTextElement"
        new FillElement color: "red"
        new Element
          location:10
          compositeMode: "destOver"
          new RectangleElement
            size: ps:1, plus:20
            location: -10
            colors: [
              "#f0f", "#ff0"
              "#f0f", "#ff0"
              "#f0f", "#ff0"
              "#f0f", "#ff0"
              "#f0f", "#ff0"
            ]
          new ShadowElement radius:10, isMask:true, filterSource:"myTextElement"

suite "Art.Engine.Elements.Filters.ShadowElement.drawArea", ->
  drawTest3 "drawArea with location",
    stagingBitmapsCreateShouldBe: 1
    elementSpaceDrawAreaShouldBe: rect 0, 0, 105, 105
    element: -> new RectangleElement
      size: 100
      new FillElement color: "red"
      new ShadowElement location: 5

  drawTest3 "drawArea with outline basic",
    elementSpaceDrawAreaShouldBe: rect -5, -5, 115, 115
    element: -> new RectangleElement
      size: 100
      new FillElement color: "yellow"
      new OutlineElement lineWidth:10, lineJoin: "round", color: "red"
      new ShadowElement location: 5

  drawTest3 "drawArea with outline with blur",
    elementSpaceDrawAreaShouldBe: rect -5, -5, 120, 120
    element: -> new RectangleElement
      size: 100
      new FillElement color: "yellow"
      new OutlineElement lineWidth:10, lineJoin: "round", color: "red"
      new ShadowElement location: 5, radius: 5

  drawTest3 "drawArea with outline with offset",
    stagingBitmapsCreateShouldBe: 1
    elementSpaceDrawAreaShouldBe: rect -5, 0, 111, 116
    element: -> new RectangleElement
      # radius: 100
      size: 100
      new FillElement color: "yellow"
      new OutlineElement lineWidth:10, lineJoin: "round", color: "red", location: y: 10
      new ShadowElement location: 1

  drawTest3 "drawArea with radius",
    stagingBitmapsCreateShouldBe: 1
    elementSpaceDrawAreaShouldBe: rect -1, -1, 112, 112
    element: -> new RectangleElement
      size: 100
      new FillElement color: "red"
      new ShadowElement location: 5, radius: 6
    test: (element) ->
      assert.eq element.drawAreaIn(Matrix.scale 2), rect(-1, -1, 112, 112).mul 2

suite "Art.Engine.Elements.Filters.ShadowElement.inverted", ->
  drawTest2 "blurred", ->
    new RectangleElement color:"red", size:point(80, 60),
      new FillElement
      new ShadowElement inverted:true, radius:10, compositeMode:"sourcein", location:point 10

  drawTest2 "no blur", ->
    new RectangleElement color:"red", size:point(80, 60), radius: 20,
      new FillElement
      new ShadowElement inverted:true, compositeMode:"sourcein", location:point 10

  drawTest2 "rotate", ->
    new RectangleElement color:"red", size:point(80, 60), radius: 20,
      new FillElement
      new ShadowElement inverted:true, compositeMode:"sourcein", angle: Math.PI/12, location:point 10

  drawTest2 "half scale", ->
    new RectangleElement color:"red", size:point(80, 60), radius: 20,
      new FillElement
      new ShadowElement axis: .5, inverted:true, compositeMode:"sourcein", scale: 1/2, radius: 10, location: ps: .5

  drawTest2 "half size", ->
    new RectangleElement color:"red", size:point(80, 60), radius: 20,
      new FillElement
      new ShadowElement
        axis: .5
        inverted:true
        compositeMode:"sourcein"
        size: ps: .5
        radius: 10
        location: ps: .5

