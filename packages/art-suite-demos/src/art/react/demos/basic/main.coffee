{log} = Foundation = require "art.foundation"
{
  createComponentFactory
  Component
  CanvasElement
  Element
  Rectangle
  TextElement
  arrayWithout
} = require "art.react"
{point} = require "art.atomic"

MyComponent = createComponentFactory class MyComponent extends Component

  getInitialState: -> toggled: false
  toggle: -> @setState toggled: !@state.toggled

  render: ->
    {toggled} = @state
    [text, clr] = if toggled
      ["and War", "red"]
    else
      ["Love", "pink"]

    CanvasElement
      canvasId: "artCanvas"
      on:
        pointerDown: @toggle
        pointerUp:   @toggle

      Rectangle color: "pink", animate: to: color: clr

      TextElement
        key: text
        location: ps: .5
        addedAnimation: from: opacity: 0, axis: point 1, .5
        removedAnimation: to: opacity: 0, axis: point 0, .5
        axis:     .5
        text:     text
        color:    "white"
        fontSize: 50

module.exports = ->
  MyComponent.instantiateAsTopComponent()
