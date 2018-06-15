{defineModule, log, mergeInto, each, lowerCamelCase} = require 'art-standard-lib'

defineModule module, -> (superClass) -> class StateFieldsMixin extends superClass

  @extendableProperty stateFields: {}

  ###
  Declare state fields you intend to use.
  IN: fields
    map from field names to initial values

  EFFECTS:
    used to initialize @state
    declares @getters and @setters for each field
    for fieldName, declares:
      @getter :fieldName
      @setter :fieldName

      if initial value is true or false:
        toggleFieldName:  -> @fieldName = !@fieldName
        setIsFieldName:   -> @fieldName = true
        clearFieldName:   -> @fieldName = false
        triggerFieldName: -> @fieldName = true

      else
        clearFieldName: -> @fieldName = null

  ###
  @stateFields: sf = (fields) ->
    @extendStateFields fields
    each fields, (initialValue, field) =>
      defaultSetValue = initialValue
      clearValue = null

      @addSetter field, (v) ->
        @setState field, if v == undefined then defaultSetValue else v
      @addGetter field, -> @state[field]

      if initialValue == true || initialValue == false
        clearValue = false
        defaultSetValue = true

        # OLD: setIsFoo
        @::[lowerCamelCase "set is #{field}"] = ->
          @setState field, true

        # NEW: triggerFoo
        @::[lowerCamelCase "trigger #{field}"] = ->
          @setState field, true

        @::[lowerCamelCase "toggle #{field}"] = ->
          @setState field, !@state[field]

      @::[lowerCamelCase "clear #{field}"] = ->
        @setState field, clearValue

  # ALIAS
  @stateField: sf
