# https://developer.mozilla.org/en-US/docs/Web/HTML/Element/Input

Foundation = require 'art-foundation'
Atomic = require 'art-atomic'
SynchronizedDomOverlay = require "./synchronized_dom_overlay"

{color} = Atomic
{createElementFromHtml} = Foundation.Browser.Dom
{log, merge, select, inspect, createWithPostCreate} = Foundation

module.exports = createWithPostCreate class TextInput extends SynchronizedDomOverlay
  # options
  #   value:      ""
  #   color:      "black"
  #   fontSize:   16 (pixels)
  #   fontFamily: "Arial"
  #   align:      "left"
  #   style:      custom style
  #   padding:    5 (pixels)
  #   attrs:      - any other input attrs you want to specify such as:
  #     maxlength:  10
  constructor: (options = {}) ->
    props = select options, "placeholder", "type", "autocapitalize", "autocomplete", "autocorrect"
    tagType = if props.type == "textarea"
      delete props.type
      "textarea"
    else
      props.type ||= 'text'
      "input"

    propsString = (for k, v of props
      "#{k}=#{inspect v}"
    ).join " "
    options.domElement = el = createElementFromHtml("<#{tagType} #{propsString}'></input>")
    el.value = options.value || ""
    style = merge options.style,
      padding: "#{options.padding || 5}px"
      border: '0px'
      color: color(options.color || "black").toString()
      padding: "0"
      margin: "0"
      "vertical-align": "bottom"
      'text-align': options.align || "left"
      'font-size': "#{options.fontSize || 16}px"
      'background-color': 'transparent'
      'font-family': options.fontFamily || "Arial"
    for k, v of style
      el.style[k] = v

    if options.attrs
      for k,v of options.attrs
        options.domElement.attr k, v
    super

    log TextInput_at_domElement:@domElement,  propsString: propsString
    @lastValue = @value
    @domElement.onchange = (event) => @checkIfValueChanged()
    @domElement.oninput  = (event) => @checkIfValueChanged()
    @domElement.onselect = (event) => @queueEvent "selectionChanged"
    @domElement.onblur   = (event) => @blur()
    @domElement.onfocus  = (event) => @focus()

  preprocessEventHandlers: (handlerMap) ->
    merge super,
      focus: => @domElement.focus()
      blur:  => @domElement.blur()
      keyUp: (e) =>
        if e.key == "enter"
          @handleEvent "enter", value:@value

  checkIfValueChanged: ->
    if @lastValue != @value
      @lastValue = @value
      @queueEvent "valueChanged",
        value: @value
        lastValue: @lastValue

  @getter
    value: -> @domElement.value
    color: -> color @domElement.css "color"

  @setter
    value: (v)-> @domElement.value = v
    color: (c)-> @domElement.css "color", c

  selectAll: ->
    @domElement.select()
