{log} = require 'art-foundation'
{Element, RectangleElement, TextElement, Component, createComponentFactory} = require 'art-react'

module.exports = createComponentFactory class ColorPreview extends Component
  module: module
  render: ->
    {color, fgColor} = @props
    Element
      size: hch:1, ww:1
      childrenLayout: "row"
      childrenAlignment: "center"
      Element
        size: wcw:1, hch:1
        RectangleElement inFlow: false, key:"ColorPreview_background", radius: 100, color: color
        TextElement
          padding: 20
          size: wcw:1, hch:1
          text: color.getHexString()
          fontFamily: "courier"
          fontSize: 40
          align: .5
          color: fgColor
