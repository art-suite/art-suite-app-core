Foundation = require "art-foundation"
Engine = require 'art-engine'
React = require 'art-react'
Atomic = require 'art-atomic'

{upperCamelCase, lowerCamelCase, log} = Foundation
{point} = Atomic
{
  Component, createComponentFactory, createAndInstantiateTopComponent
  CanvasElement
  Element
  RectangleElement
  PagingScrollElement
  TextElement
} = React

Demos = require "./demos"

Engine.FullScreenApp.init
  title: "Art.React.Demos"
.then ->
  DemoButton = createComponentFactory
    module: module

    selectDemo: ->
      @props.selectDemo @props.name

    render: ->
      {name} = @props
      TextElement
        fontFamily: "Helvetica"
        color:    "#0007"
        text:     name
        padding: 10
        on: pointerClick: @selectDemo

  createAndInstantiateTopComponent
    module: module

    selectDemo: (name)->
      @setState selectedDemo: name

    deselectDemo: ->
      @setState selectedDemo: null

    toggle: ->
      @setState toggled: !@state.toggled

    render: ->
      {selectedDemo, toggled} = @state
      log toggled:toggled

      CanvasElement
        childrenLayout: "column"
        Element
          size: ww:1, h:50
          childrenLayout: "row"
          childrenAlignment: "centerLeft"
          RectangleElement inFlow: false, color: "#333", padding: -10
          padding: 10
          selectedDemo &&
            Element
              size: cs: 1
              RectangleElement color: "#555", radius: 5
              on: pointerClick: @deselectDemo
              TextElement
                color:    "#fffc"
                text:     "back"
                fontSize: 16
                fontFamily: "Helvetica"
                margin: 10
                padding: h:10, v:5

          TextElement
            color:    "#fffc"
            text:     if selectedDemo then selectedDemo else "art-react-demos"
            fontSize: 20
            fontFamily: "Helvetica"
            margin: 10

        Element null,
          if selectedDemo
            Element
              key: "demo-#{selectedDemo}"
              clip: true
              animators: axis: voidValue: point -1, 0

              Demos[selectedDemo].Main()
          else

            Element
              key: "select-demo"
              childrenLayout: "column"
              animators: axis: voidValue: "topRight"
              RectangleElement inFlow: false, color: "#eee"
              for demo in Demos.namespaces
                DemoButton name:demo.name, selectDemo:@selectDemo

