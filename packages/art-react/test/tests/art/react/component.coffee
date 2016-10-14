Foundation = require 'art-foundation'
Engine = require 'art-engine'
React = require 'art-react'
{log, merge} = Foundation

{stateEpoch} = Engine.Core.StateEpoch

{Element, RectangleElement, createComponentFactory, Component, VirtualElement, ReactArtEngineEpoch} = React
{reactArtEngineEpoch} = ReactArtEngineEpoch

module.exports = suite:
  instantiate: ->
    test "basic", ->
      class MyComponent extends Component
        render: ->
          Element name:"foo"

      c = new MyComponent
      assert.eq c.state, {}
      c._instantiate()
      assert.eq c.element, c._virtualAimBranch.element
      assert.eq c.element.class, Engine.Core.Element
      assert.eq c.element.pendingName, "foo"

    test "instantiateAsTopComponent", (done)->
      MyComponent = createComponentFactory
        render: ->
          Element key: "child"

      c = MyComponent().instantiateAsTopComponent parent = new Engine.Core.Element name: "parent"
      parent.onNextReady ->
        assert.eq c.element.parent, parent
        assert.eq ["child"], (child.name for child in parent.children)
        done()

  props: ->
    test "basic", ->
      MyFactory = createComponentFactory render: -> Element()
      c = MyFactory foo: 123
      assert.eq c.props, foo: 123

    test "strings become text: string", ->
      MyFactory = createComponentFactory render: -> Element()
      c = MyFactory "foo"
      assert.eq c.props, text: ["foo"]

    test "multiple strings", ->
      MyFactory = createComponentFactory render: -> Element()
      c = MyFactory "foo", bar: 123, "bad"
      assert.eq c.props, text: ["foo", "bad"], bar: 123

  render: ->
    test "render", ->
      class MyComponent extends Component
        render: ->
          RectangleElement color: "red"

      c = new MyComponent
      rendered = c.render()
      log rendered:rendered, rendered.class, VirtualElement, instanceof:rendered.class instanceof VirtualElement
      assert.ok rendered.class.constructor instanceof VirtualElement.constructor
      assert.eq rendered.elementClassName, "RectangleElement"
      assert.eq rendered.props, color: "red"
      assert.eq rendered.children, []

    test "render with children", ->
      class MyComponent extends Component
        render: ->
          Element {},
            RectangleElement color: "red"
            RectangleElement color: "blue"

      c = new MyComponent
      rendered = c.render()
      assert.ok rendered.class.constructor instanceof VirtualElement.constructor
      assert.eq rendered.elementClassName, Engine.Core.Element.name
      assert.eq rendered.props, {}
      assert.ok rendered.children[0].class.constructor instanceof VirtualElement.constructor
      assert.eq rendered.children[0].elementClassName, "RectangleElement"
      assert.eq rendered.children[0].props, color: "red"
      assert.eq rendered.children[0].children, []

      assert.ok rendered.children[1].class.constructor instanceof VirtualElement.constructor
      assert.eq rendered.children[1].elementClassName, "RectangleElement"
      assert.eq rendered.children[1].props, color: "blue"
      assert.eq rendered.children[1].children, []

    test "render & instantiate with sub-components", ->
      subComponentRenderCount = 0
      class MySubComponent extends Component
        render: ->
          subComponentRenderCount++
          Element name: @props.name

      mySubComponentFactory = MySubComponent.toComponentFactory()

      class MyComponent extends Component
        render: ->
          Element
            name: "foo"
            mySubComponentFactory name: "subfoo"

      c = new MyComponent
      rendered = c.render()
      assert.eq subComponentRenderCount, 0
      assert.eq rendered.props.name, "foo"
      assert.eq rendered.children.length, 1
      assert.eq rendered.children[0].props.name, "subfoo"
      assert.ok rendered.children[0] instanceof MySubComponent
      assert.eq rendered.children[0].element, null

      c._instantiate()
      assert.eq subComponentRenderCount, 1
      assert.eq c.element.pendingName, "foo"
      assert.eq c.element.pendingChildren.length, 1
      assert.eq c.element.pendingChildren[0].pendingName, "subfoo"
      assert.eq c.element.pendingChildren[0].pendingChildren.length, 0

  getInitialState: ->
    test "basic", ->
      class MyComponent extends Component
        getInitialState: ->
          foo: "bar"
        render: ->
          Element name:@state.foo

      (c = new MyComponent)._instantiate()
      assert.eq c.state, foo:"bar"
      assert.eq c.element.pendingName, "bar"

    test "with setState {}", ->
      class MyComponent extends Component
        getInitialState: ->
          @setState bar: "sally"
          foo: "george"

        render: -> Element name:@state.foo

      (c = new MyComponent)._instantiate()
      assert.eq c.state, foo:"george", bar:"sally"
      assert.eq false, !!reactArtEngineEpoch.epochQueued

    test "with setState key, value", ->
      class MyComponent extends Component
        getInitialState: ->
          @setState "bar", "sally"
          foo: "george"

        render: -> Element name:@state.foo

      (c = new MyComponent)._instantiate()
      assert.eq c.state, foo:"george", bar:"sally"
      assert.eq false, !!reactArtEngineEpoch.epochQueued

  functionsBoundToInstances:
    basic: ->
      test "use bound function", ->
        class MyComponent extends Component
          getInitialState: -> foo: "bar"
          updateState: -> @setState foo: "baz"
          render: -> Element name: @state.foo

        (c = new MyComponent)._instantiate()
        assert.eq c.state, foo:"bar"
        {updateState} = c
        updateState();
        c.onNextReady ->
          assert.eq c.state, foo:"baz"
          assert.eq c.element.pendingName, "baz"

      test "getBoundFunctionList() empty", ->
        class MyComponent extends Component
          render: -> Element()

        (c = new MyComponent)._instantiate()
        assert.eq c.getBoundFunctionList(), []

      test "getBoundFunctionList() with one entry", ->
        class MyComponent extends Component
          foo: ->
          render: -> Element()

        (c = new MyComponent)._instantiate()
        assert.eq c.getBoundFunctionList(), ["foo"]

    mixins: ->
      test "basic", ->
        FooMixin = (superClass) -> class Foo extends superClass
          foo: ->
            @setState foo: "foo"
            @

        c = new class MyComponent extends FooMixin Component
          @stateFields bar: "bar"
          render: -> Element()

        {foo} = c._instantiate()
        foo().onNextReady (ret) ->
          assert.eq c.state, bar: "bar", foo: "foo"

  setState: ->

    test "setState Object", (done)->
      class MyComponent extends Component
        getInitialState: ->
          foo: "bar"
        render: ->
          Element name:@state.foo

      (c = new MyComponent)._instantiate()
      assert.eq c.state, foo:"bar"
      c.setState foo:"baz", ->
        assert.eq c.state, foo:"baz"
        assert.eq c.element.pendingName, "baz"
        done()
      assert.eq c.state, foo:"bar"
      assert.eq c.element.pendingName, "bar"

    test "setState string, value", (done)->
      class MyComponent extends Component
        getInitialState: ->
          foo: "bar"
        render: ->
          Element name:@state.foo

      (c = new MyComponent)._instantiate()
      assert.eq c.state, foo:"bar"
      c.setState "foo", "baz", ->
        assert.eq c.state, foo:"baz"
        assert.eq c.element.pendingName, "baz"
        done()
      assert.eq c.state, foo:"bar"
      assert.eq c.element.pendingName, "bar"

  stateFields:
    basic: ->
      test "basics", ->
        class MyComponent extends Component
          @stateFields foo: "bar"
          render: -> Element()

        c = new MyComponent
        assert.eq c.state, {}
        c._instantiate()
        assert.eq c.state, foo: "bar"

      test "falsish default values are preserved", ->
        class MyComponent extends Component
          @stateFields falsy: false, zero: 0, nully: null, undefinedish: undefined
          render: -> Element()

        c = new MyComponent
        assert.eq c.state, {}
        assert.eq c._instantiate().state, falsy: false, zero: 0, nully: null, undefinedish: undefined

      test "getters and setters", ->
        class MyComponent extends Component
          @stateFields foo: "bar"
          render: -> Element()

        c = new MyComponent
        assert.eq c.state, {}
        c._instantiate()
        assert.eq c.state, foo: "bar"
        assert.eq c.foo, "bar"
        c.foo = "baz"
        c.onNextReady()
        .then ->
          assert.eq c.state, foo: "baz"

      test "getInitialState has priority", ->
        class MyComponent extends Component
          @stateFields foo: "bar"
          getInitialState: -> foo: "baz"
          render: -> Element()

        c = new MyComponent
        assert.eq c.state, {}
        c._instantiate()
        assert.eq c.state, foo: "baz"

    mixins: ->
      test "basics", ->
        FooMixin = (superClass) -> class Foo extends superClass
          @stateFields foo: "foo"

        class MyComponent1 extends FooMixin Component
          @stateFields bar: "bar"
          render: -> Element()

        class MyComponent2 extends FooMixin Component
          @stateFields baz: "baz"
          render: -> Element()

        c = new MyComponent1
        assert.eq c.state, {}
        assert.eq c._instantiate().state, foo: "foo", bar: "bar"

        c = new MyComponent2
        assert.eq c.state, {}
        assert.eq c._instantiate().state, foo: "foo", baz: "baz"

  refs: ->
    test "basic", ->
      rr = null
      br = null
      class MyComponent extends Component
        render: ->
          Element {},
            rr = RectangleElement key:"redRectangle", color: "red"
            br = RectangleElement key:"blueRectangle", color: "blue"

      c = new MyComponent
      c._instantiate()
      assert.eq true, c.refs.redRectangle == rr
      assert.eq true, c.refs.blueRectangle == br

    test "duplicate refs warning", ->
      rr = null
      br = null
      class MyComponent extends Component
        render: ->
          Element {},
            rr = RectangleElement key:"redRectangle", color: "red"
            br = RectangleElement key:"redRectangle", color: "blue"

      c = new MyComponent
      c._instantiate()

    test "refs to children passed to component should be bound to the component they are rendered in", ->
      rr = null
      br = null
      Wrapper = createComponentFactory
        render: ->
          Element
            key: "wrapper"
            @props.children

      class MyComponent extends Component
        render: ->
          Wrapper {},
            rr = RectangleElement key:"redRectangle", color: "red"
            br = RectangleElement key:"blueRectangle", color: "blue"

      c = new MyComponent
      c._instantiate()
      assert.eq ["wrapper"], Object.keys(c._virtualAimBranch.refs)
      assert.eq ["blueRectangle", "redRectangle"], Object.keys(c.refs).sort()
      assert.eq true, c.refs.redRectangle == rr
      assert.eq true, c.refs.blueRectangle == br

  "children prop": ->

    test "children passed to component-factory become @props.children", (done)->
      Wrapper = createComponentFactory
        render: ->
          Element
            key: "wrapper"
            @props.children

      class MyComponent extends Component
        render: ->
          Wrapper {},
            RectangleElement color: "red"
            RectangleElement color: "blue"

      c = new MyComponent
      c._instantiate()
      c.element.onNextReady ->
        assert.eq c.element.key, "wrapper"
        assert.eq ["#ff0000", "#0000ff"], (child.color.toString() for child in c.element.children)
        done()

  canUpdateFrom: ->
    test "_canUpdateFrom matching Component-classes == true", ->
      class MyComponent1 extends Component
        render: -> Element name: @props.name

      a = new MyComponent1 name: "foo"
      b = new MyComponent1 name: "bar"
      assert.eq true, a._canUpdateFrom b


    test "_canUpdateFrom missmatched Component-classes == false", ->
      class MyComponent1 extends Component
        render: -> Element name: @props.name
      class MyComponent2 extends Component
        render: -> Element name: @props.name

      a = new MyComponent1 name: "foo"
      b = new MyComponent2 name: "bar"
      assert.eq false, a._canUpdateFrom b

    test "_canUpdateFrom matching Component-classes == false", ->
      class MyComponent1 extends Component
        render: -> Element name: "baz"

      a = new MyComponent1 key: "foo"
      b = new MyComponent1 key: "bar"
      assert.eq false, a._canUpdateFrom b

    test "_canUpdateFrom Component and VirtualElement-classes == false", ->
      class MyComponent1 extends Component
        render: -> Element name: "baz"

      a = new MyComponent1 key: "foo"
      b = Element {}
      assert.eq false, a._canUpdateFrom b
      assert.eq false, b._canUpdateFrom a

  updateFrom: ->
    test "_updateFrom basic", ->
      class MyComponent1 extends Component
        render: -> Element name: @props.name

      (a = new MyComponent1 name: "foo")._instantiate()
      b = new MyComponent1 name: "bar"
      a._updateFrom b
      assert.eq a.props.name, "bar"

    test "_updateFrom add component", ->
      myComponent1 = createComponentFactory class MyComponent1 extends Component
        render: -> Element name: @props.name

      a = Element
        name: "foo"
        Element name: "child1"
      b = Element
        name: "bar"
        Element name: "child1"
        myComponent1 name: "child2"

      a._instantiate {}
      a._updateFrom b
      stateEpoch.onNextReady()
      .then ->
        assert.eq ["child1", "child2"], (child.props.name for child in a.children)
        assert.eq ["child1", "child2"], (child.name for child in a.element.children)

    test "_updateFrom remove component", ->
      myComponent1 = createComponentFactory class MyComponent1 extends Component
        render: -> Element name: @props.name

      a = Element
        name: "foo"
        Element name: "child1"
        myComponent1 name: "child2"
        Element name: "child3"
      b = Element
        name: "bar"
        Element name: "child1"
        Element name: "child3"

      a._instantiate {}
      a._updateFrom b
      stateEpoch.onNextReady()
      .then ->
        assert.eq ["child1", "child3"], (child.props.name for child in a.children)
        assert.eq ["child1", "child3"], (child.name for child in a.element.children)

  tools: ->
    test "find", (done)->
      MySubComponent = createComponentFactory class MySubComponent extends Component
        render: -> Element()

      MyTopComponent = createComponentFactory class MyTopComponent extends Component
        render: ->
          Element {},
            MySubComponent key: "key1"
            MySubComponent
              key: "key2"
              MySubComponent
                key: "subKey1"

      instance = MyTopComponent()
      instance._instantiate()

      stateEpoch.onNextReady ->
        verbose = false
        assert.eq ["key1"],                     (found.key for found in instance.find("key1",   verbose:verbose))
        assert.eq ["key1", "key2"],             (found.key for found in instance.find("key",    verbose:verbose))
        assert.eq ["subKey1"],                  (found.key for found in instance.find("subKey", verbose:verbose))
        assert.eq ["key1", "key2", "subKey1"],  (found.key for found in instance.find("ey",     verbose:verbose)).sort()
        done()
