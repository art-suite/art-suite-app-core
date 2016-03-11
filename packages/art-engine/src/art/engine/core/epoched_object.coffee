Foundation = require 'art-foundation'
Events = require 'art-events'
StateEpoch = require "./state_epoch"

{
  log
  BaseObject
  capitalize
  compactFlatten
  isNumber
  isFunction
  shallowEq
  plainObjectsDeepEq
} = Foundation
{propInternalName} = BaseObject
blankOptions = {}
{stateEpoch} = StateEpoch
statePropertyKeyTest = /^_[a-z].*$/    # anything with an underscore then letter at the beginning

module.exports = class EpochedObject extends BaseObject
  @propsEq: propsEq = plainObjectsDeepEq
  @shallowPropsEq: shallowPropsEq = shallowEq

  ############################
  # PROPERTIES
  ############################
  ###

  CONCRETE PROPERTIES
  -------------------

  Concrete-properties (non-virtual properties), once declared, take care of many common property tasks.
  For a property "foo":

    * @_foo and @_pendingState._foo are initialized on Element-instantiation
      - They are either intialized to default values (which are validated for consistency) or
      - Can be initialized by the instantiating code. Ex: new Element foo:123
    * Defines the following API
      - element.foo       # getter, returns @_foo
      - element.getFoo()  # old-school, alternative getter - faster in some browsers (Safari7 is 100x faster, Safary8 is 3x faster. Chrome is same speed.)
      - element.foo = v   # setter
      - element.setFoo(v) # old-school, alternative setter
      - element.pendingFoo / getPendingFoo() # returns @_pendingState.foo
      - element.fooChanged / getFooChanged() # returns propsEq @foo, @pendingFoo
    * Elements can override the default values for properties by setting:
      - prototype.defaultFoo to something other than undefined
      - Ex:
        class MyElement extends Element
          defaultSize: ps:1
    * Populates @class.metaProperties.foo with things like default values, names, preprocessors, etc...
      (this code is in flux; see below for current implementation)

  options:
    default:  # default value set when the Element is created
    setter: (rawNewValue, oldValue, preprocessAndValidate) ->
      THIS: the Element
      IN:
        rawNewValue: the exact, unprocessed, unvalidated value of 'foo' passed by the setYourProp(foo) or @yourProp = foo statement.
        oldValue: the (custom-setter-processed) value that was last set (i.e. the value in @_pendingState)
        preprocessAndValidate: your custom preprocessor and validator are merged into a single function you can use
          as part of your custom setter if desired. A no-op function is provided by default, so this is always a valid function.
      OUT: It should return the value to set in @_pendingState.
      SIDE EFFECTS:
        It should NOT actually set the value in @ or @_pendingState.
        It is best to use setProperty calls for all side-effects. This maintains the epoch
        consistency model: mutations only modify pendingState, not current-state.

      TODO:
        Verify and implement:
          Depricate concrete property setters:
            They are obsolete now that we can have postSetters.
            "postSetter" plus "preprocess" covers everything, I think.

      Use when:
        a) you need to do update other poperties when this one changes AND/OR
        b) you need to do something different when actually setting the value
           as opposed to simply preprocessing the value.
           NOTE: animations use the preprocessor when initializing their to and from values.

    postSetter: (newValue, oldValue) ->
      THIS: the Element
      IN:
        newValue: the value after it has passed through the preprocessor and/or setter
        oldValue: the (custom-setter-processed) value that was last set
          i.e. the value in @_pendingState before the setter was called
      OUT: ignored
      STATE: @_pendingState has been updated with newValue; getPendingPropertyName() will return newValue
      SIDE EFFECTS:
        It is best to use setProperty calls for all side-effects. This maintains the epoch
        consistency model: mutations only modify pendingState, not current-state.

      Use when:
        a) You need to update other properties when this one changes. The simplest example is when
          this property defines default values for other properties that haven't been set yet.
        b) You need to fire off events when this property changes.

      This is particularly useful when writing custom Elements which consist of a struture of other
      elements. Often you'll want to update that structure in response to properties being set.

    preprocess: (rawValue) -> processedValue
      IN: raw setter input
      THIS: not set
      OUT: normalized value to actually set

    validate: (rawValue) -> boolean
      IN: raw value
      THIS: not set
      OUT: true or false
      Return false if the input is invalid which will trigger an exception.

  In all cases _elementChanged executes every time the property is set
  .setter takes precidence over .preprocess takes precidence over .validate; you can only have one

  VIRTUAL PROPERTIES
  ------------------

  Virtual properties are specified with the class method: @virtualProperty

  VPs have the same API from the client's perspective, but they don't have any storage in @ or @_pendingState.
  Virtual properties are used as alternative "views" into the Element's state. Ex:

     @currentLocation isn't actually stored as a point. It is derived from @elementToParentMatrix and @axis.

  As a short-cut, you can supply just a getter function instead of options to define a
  virtual property. See getter below for details. Here is how to use this shortcut:

    @virtualProperty
      foo: (pending) -> ...

  Virtual property options (when isPlainObject options)

    getter: (pending) ->
      REQUIRED
      THIS: the Element
      IN:   pending: true/false
      OUT:  if pending, return the pending value, else the current value

    setter: (rawNewValue, preprocessAndValidate) ->
      OPTIONAL
        If not provided, this virtual property cannot be set.
        Attempting to set this virtual property will be IGNORED
        I.E. attempting to set this property does not trigger errors.

      THIS: the Element
      IN:
        rawNewValue: the value passed in by the client
        preprocessAndValidate: your custom preprocessor and validator are merged into a single function you can use
          as part of your custom setter if desired. A no-op function is provided by default, so this is always a valid function.
      OUT: ignored

    validate: (v) ->
    preprocess: (v) ->
      works the same as the options for concrete-properties
      except they are only used by:
        preprocessAndValidate function passed to the setter
        animations

  Virtual vs Concrete properties:

    * Virutal props don't have default values
    * Virtual props don't create property slots in Element instances or their _pendingState, BUT
    * Virtual props can have their setters invoked from initializers
    * preprocessors and validators can be specified
    * getter - you must specify a custom getter, see getter option above
    * setter specification/semantics are a little different. See setter option above

  ###
  @_defineElementProperty: (externalName, options={})  ->
    internalName = propInternalName externalName

    customValidator = options.validate
    customPreprocessor = options.preprocess

    preprocessor = if customPreprocessor && customValidator
      if customPreprocessor.length > 1 || customValidator.length > 1
        (v, oldValue) ->
          throw new Error "invalid value for #{externalName}: #{inspect v}" unless customValidator v, oldValue
          customPreprocessor v, oldValue
      else
        (v) ->
          throw new Error "invalid value for #{externalName}: #{inspect v}" unless customValidator v
          customPreprocessor v
    else if customValidator
      if customValidator.length > 1
        (v, oldValue) ->
          throw new Error "invalid value for #{externalName}: #{inspect v}" unless customValidator v, oldValue
          v
      else
        (v) ->
          throw new Error "invalid value for #{externalName}: #{inspect v}" unless customValidator v
          v
    else customPreprocessor || (v) -> v

    metaProperties =
      internalName: internalName
      externalName: externalName
      preprocessor: preprocessor
      getterName: @_propGetterName externalName
      setterName: @_propSetterName externalName

    if options.virtual
      metaProperties.virtual = true

      # if no setter, setting a virtual property is simply ignored
      _setter = options.setter || ->
      _getter = options.getter

      getter        = _getter
      pendingGetter = -> _getter.call @, true
      setter        = (rawValue) -> _setter.call @, rawValue, preprocessor

    else
      metaProperties.defaultValue = defaultValue = preprocessor options.default

      getter        = (pending) -> if pending then @_pendingState[internalName] else @[internalName]
      pendingGetter = -> @_pendingState[internalName]

      {layoutProperty, drawProperty, drawAreaProperty, postSetter, setter} = options
      setter = if customSetter = setter
        if postSetter
          (v) ->
            oldValue = @_pendingState[internalName]
            newValue = v
            @_pendingState[internalName] = customSetter.call @, newValue, oldValue, preprocessor
            @_elementChanged layoutProperty, drawProperty, drawAreaProperty
            postSetter.call @, newValue, oldValue
            newValue
        else
          (v) ->
            oldValue = @_pendingState[internalName]
            newValue = v
            @_pendingState[internalName] = customSetter.call @, newValue, oldValue, preprocessor
            @_elementChanged layoutProperty, drawProperty, drawAreaProperty
            newValue
      else if postSetter
        (v) ->
          oldValue = @_pendingState[internalName]
          newValue = @_pendingState[internalName] = preprocessor v, oldValue
          @_elementChanged layoutProperty, drawProperty, drawAreaProperty
          postSetter.call @, newValue, oldValue
          newValue
      else if preprocessor.length > 1
        (v) ->
          oldValue = @_pendingState[internalName]
          newValue = @_pendingState[internalName] = preprocessor v, oldValue
          @_elementChanged layoutProperty, drawProperty, drawAreaProperty
          newValue
      else
        (v) ->
          newValue = @_pendingState[internalName] = preprocessor v
          @_elementChanged layoutProperty, drawProperty, drawAreaProperty
          newValue

      @_getPropertyInitializerList().push [internalName, defaultValue, externalName]
      # @_getPropertyInitializerDefaultValuesList().push defaultValue

    @_getMetaProperties()[externalName] = metaProperties

    @_addGetter @::, externalName,                         getter
    @_addGetter @::, "pending" + capitalize(externalName), pendingGetter
    @_addGetter @::, externalName + "Changed",             -> !shallowPropsEq getter.call(@), pendingGetter.call(@)
    @_addSetter @::, externalName,                         setter

  @concreteProperty: (map)->
    for prop, options of map
      @_defineElementProperty prop, options

  @virtualProperty: (map)->
    for prop, options of map
      options = getter: options if isFunction options
      options.virtual = true
      @_defineElementProperty prop, options

  # list of tupples, one per property:
  #   [externalName, preprocessor, setter]
  # @_getVirtualPropertyInitializerList: -> @getPrototypePropertyExtendedByInheritance "virtualPropertyInitializerList", []

  # list of tupples, one per property:
  #   [externalName, internalName, preprocessor, defaultValue]
  @_getPropertyInitializerList: -> @getPrototypePropertyExtendedByInheritance "propertyInitializerList", []
  # @_getPropertyInitializerDefaultValuesList: -> @getPrototypePropertyExtendedByInheritance "propertyInitializerDefaultValuesList", []

  # properties of properties:
  #   externalName:
  #   internalName:
  #   preprocessor:
  #   defaultValue:
  #   setterName:
  #   getterName:
  @_getMetaProperties: -> @getPrototypePropertyExtendedByInheritance "metaProperties", {}

  @generateSetPropertyDefaults: ->
    propertyInitializerList = @_getPropertyInitializerList()
    metaProperties = @_getMetaProperties()
    functionString = compactFlatten([
      "(function(options) {"
      "var _pendingState = this._pendingState;"
      # "var propertyInitializerList = this.propertyInitializerList;"
      # "var propertyInitializerDefaultValuesList = this.propertyInitializerDefaultValuesList;"
      "var metaProperties = this.metaProperties;"
      for [k, v, externalName], i in propertyInitializerList

        value = if (defaultOverride = @::[defaultName = "default" + capitalize externalName]) != undefined
          if preprocessor = metaProperties[externalName].preprocessor
            @::[defaultName] = preprocessor defaultOverride
          "this.#{defaultName}"
        else if v == null || v == false || v == true || v == undefined || isNumber(v)
          v
        else
          # NOTE: metaPropererties approach seems slower on Safari.
          # "propertyInitializerList[#{i}][1]"
          # "propertyInitializerDefaultValuesList[#{i}]"
          "metaProperties.#{externalName}.defaultValue;"
        "this.#{k} = _pendingState.#{k} = #{value};"
      # NOTE: This seems to be slower than just scanning the options even though scanning the options is slowish.
      # for externalName, {setterName, virtual} of metaProperties when !virtual
      #   "if (options.#{externalName} != undefined) this.#{setterName}(options.#{externalName});"
      # for externalName, {setterName, virtual} of metaProperties when virtual
      #   "if (options.#{externalName} != undefined) this.#{setterName}(options.#{externalName});"
      "})"
    ]).join "\n"
    eval functionString

  virtualPropertySecondPassMetaProperties = []
  virtualPropertySecondPassValues = []
  _initProperties: (options) ->
    {metaProperties} = @

    unless @__proto__.hasOwnProperty "_initPropertiesAuto"
      @__proto__._initPropertiesAuto = @class.generateSetPropertyDefaults()

    @_initPropertiesAuto options

    # IMPRORTANT OPTIMIZATION NOTE:
    # Creating _initPropertiesAuto the first time we instantiate the class is 2-4x faster than:
    # {propertyInitializerList, _pendingState} = @
    # for internalName, defaultValue of propertyInitializerList
    #   @[internalName] = _pendingState[internalName] = defaultValue

    virtualCount = 0
    for k, v of options when v != undefined && mp = metaProperties[k]
      if mp.virtual
        virtualPropertySecondPassMetaProperties[virtualCount] = mp
        virtualPropertySecondPassValues[virtualCount++] = v
      else
        @[mp.setterName] v

    # set virtual properties after concrete
    # for k, v of options when (mp = metaProperties[k]) && mp.virtual
    for i in [0...virtualCount]
      mp = virtualPropertySecondPassMetaProperties[i]
      v = virtualPropertySecondPassValues[i]
      @[mp.setterName] v

    @_elementChanged true, true, true
    null

  # set each property in propertySet if it is a legitimate property; otherwise it is ignored
  setProperties: (propertySet) ->
    metaProperties = @metaProperties
    for property, value of propertySet
      mp = metaProperties[property]
      unless mp.virtual
        @[setterName] value if setterName = mp?.setterName

    propertySet

  # set all properties, use propertySet values if present, otherwise use defaults
  # TODO: this sets @parent and @children, it shouldn't, but they aren't virtual...
  # TODO: if this is used much, it would be faster to have a concreteMetaProperties array so we don't have to test mp.virtual
  #   this "concreteMetaProperties" array would not include parent or children
  replaceProperties: (propertySet) ->
    metaProperties = @metaProperties
    for property, mp of metaProperties when !mp.virtual
      externalName = mp.externalName
      @[mp.setterName]? if propertySet.hasOwnProperty(externalName)
        propertySet[externalName]
      else
        mp.defaultValue
    propertySet

  setProperty: (property, value) ->
    if mp = @metaProperties[property]
      @[mp.setterName]? value

  # reset property to its default
  resetProperty: (property) ->
    if mp = @metaProperties[property]
      @[mp.setterName]? mp.defaultValue

  # used by Animator / Foundation.Transaction to normalize to/from values
  preprocessProperties: (propertySet) ->
    metaProperties = @metaProperties
    for property, value of propertySet when mp = metaProperties[property]
      propertySet[property] = mp.preprocessor value, @[mp.internalName]
    propertySet

  getPendingPropertyValues: (propertyNames) ->
    ret = {}
    for property in propertyNames when metaProp = @metaProperties[property]
      ret[property] = @_pendingState[metaProp.internalName]
    ret

  getPropertyValues: (propertyNames) ->
    ret = {}
    for property in propertyNames when metaProp = @metaProperties[property]
      ret[property] = @[metaProp.internalName]
    ret

  _getChangingStateKeys: ->
    k for k, v of @_pendingState when statePropertyKeyTest.test(k) && (!shallowPropsEq @[k], @_pendingState[k])

  _logPendingStateChanges: ->
    oldValues = {}
    newValues = {}
    for k, v of @_pendingState when !(k.match /^__/) && !plainObjectsDeepEq v, @[k]
      oldValues[k] = @[k]
      newValues[k] = v
    log "ElementBase pending state changes": element: @inspectedName, old: oldValues, new: newValues

  @getter
    props: ->
      ret = {}
      for k, {virtual} of @metaProperties
        ret[k] = @[k]
      ret

    concreteProps: ->
      ret = {}
      for k, {internalName, virtual} of @metaProperties when !virtual
        ret[k] = @[internalName]
      ret

    virtualProps: ->
      ret = {}
      for k, {virtual} of @metaProperties when virtual
        ret[k] = @[k]
      ret

  ##########################
  # EPOCHED STATE
  ##########################
  _getIsChangingElement: -> stateEpoch._isChangingElement @

  onNextReady: (callback, forceEpoch = true) ->
    stateEpoch.onNextReady callback, forceEpoch

  @onNextReady: (callback, forceEpoch = true) ->
    stateEpoch.onNextReady callback, forceEpoch

  onIdle: (callback) ->
    stateEpoch.onNextReady callback

  getState: (pending = false) ->
    if pending then @_pendingState else @

  _elementChanged: (layoutPropertyChanged, drawPropertyChanged, drawAreaPropertyChanged)->
    {_pendingState} = @

    if layoutPropertyChanged
      if StateEpoch._stateEpochLayoutInProgress
        console.error "__layoutPropertiesChanged while _stateEpochLayoutInProgress"
      _pendingState.__layoutPropertiesChanged  = true

    @__drawPropertiesChanged     = true if drawPropertyChanged
    @__drawAreaChanged           = true if drawAreaPropertyChanged

    unless _pendingState.__addedToChangingElements
      _pendingState.__addedToChangingElements = true
      stateEpoch._addChangingElement @

  ###
  TODO:
    It would probably be faster overall to:

      a) move all the __* properties out of _pendingState
        Probably just promote them to the Element itself

      b) replace _pendingState with a new, empty object after _applyStateChanges

      c) for faster Element creation
        - could we just say the Element "consumes" the props passed to it on creation?
        - then we can alter that props object
        - every prop in the passed-in props object gets run through the preprocessors/validators
        - and the result is assigned back to the props object
        - then the props object BECOMES the first @_pendingState

  ###
  _applyStateChanges: ->

    for k, v of @_pendingState
      @[k] = v if statePropertyKeyTest.test k

    @_pendingState.__addedToChangingElements = false

  ######################
  # Public
  ######################
  constructor: (options = blankOptions)->
    super
    @remoteId = null

    @_pendingState =
      __layoutPropertiesChanged: false
      __depth: 0
      __addedToChangingElements: false
    @_initProperties options

    @__redrawRequired = true
    @__drawAreaChanged = true
    @__drawPropertiesChanged = true
